//
//  TCSLaunchDaemonManager.m
//  TomcatSlapper
//
//  Created by John Clayton on 12/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSLaunchDaemonManager.h"
#import "TCSLaunchDaemonManager+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSKitty.h"
#import "TCSAuthorizationHandler.h"
#import "TCSIOUtils.h"

#include <sys/types.h>
#include <sys/acl.h>
#include <unistd.h>

static NSString *daemonPath = @"/Library/LaunchDaemons/";
static NSString *agentPath = @"~/Library/LaunchAgents/";

static NSString *daemonTemplateName = @"daemon.template.plist";
static NSString *agentTemplateName = @"agent.template.plist";

static NSString *fsaclctlCommand = @"/usr/sbin/fsaclctl";
static NSString *chmodCommand = @"/bin/chmod";

@implementation TCSLaunchDaemonManager


// OBJECT STUFF ============================================================= //

- (void) awakeFromNib {
    daemons = [[NSMutableDictionary alloc] init];
    agents = [[NSMutableDictionary alloc] init];
}

- (void) dealloc {
    [daemons release];
    [agents release];
    [super dealloc];
}


// DAEMON MANAGEMENT ======================================================== //

#pragma mark Daemon Management

- (void) installACLs {
    TCSAuthorizationHandler *authHandler = [TCSAuthorizationHandler sharedAuthHandler];
    if([authHandler isAuthorized]) {
        [self _enableACLs:[authHandler authorization]];
        [self _addACLEntry:[authHandler authorization]];
    } else {
        logError(@"Not authorized to enable ACLs");
        [NSException raise:TCSExceptionCouldNotEnableACLs
                    format:@"Not authorized to enable ACLs"];
    }
}

- (void) setAutomaticStartupTypeForKitty:(TCSKitty *)tk {
    logDebug(@"setAutomaticStartupTypeForKitty:");
    TCSAutomaticStartupType type = [tk automaticStartupType];
    id daemon = nil;
    id agent = [self agentForKitty:tk];
    switch (type) {
        case TCS_NEVER:
            logDebug(@"set TCS_NEVER");
            // disable user agent
            [agent setObject:[NSNumber numberWithBool:YES] forKey:TCSDaemonKeyDisabled];
            [self _writePlist:agent forKitty:tk type:TCS_USER_LOGIN];
            // disable system daemon
            if([TCSLaunchDaemonManager didInstallACLs]) {
                daemon = [self daemonForKitty:tk];
                [daemon setObject:[NSNumber numberWithBool:YES] forKey:TCSDaemonKeyDisabled];
                [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
            }
            break;
        case TCS_SYSTEM_BOOT:
            logDebug(@"set TCS_SYSTEM_BOOT");
            if([TCSLaunchDaemonManager didInstallACLs]) {
                // enable system daemon
                daemon = [self daemonForKitty:tk];
                [daemon setObject:[NSNumber numberWithBool:NO] forKey:TCSDaemonKeyDisabled];
                [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
            }
            // disable user agent
            [agent setObject:[NSNumber numberWithBool:YES] forKey:TCSDaemonKeyDisabled];
            [self _writePlist:agent forKitty:tk type:TCS_USER_LOGIN];
            break;
        case TCS_USER_LOGIN:
            logDebug(@"set TCS_USER_LOGIN");
            if([TCSLaunchDaemonManager didInstallACLs]) {
                // disable system daemon
                daemon = [self daemonForKitty:tk];
                [daemon setObject:[NSNumber numberWithBool:YES] forKey:TCSDaemonKeyDisabled];
                [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
            }
            // enable user agent
            [agent setObject:[NSNumber numberWithBool:NO] forKey:TCSDaemonKeyDisabled];
            [self _writePlist:agent forKitty:tk type:TCS_USER_LOGIN];
            break;
        default:
            break;
    }
}

- (void) setEnvironmentForKitty:(TCSKitty *)tk {
    logDebug(@"setEnvironmentForKitty:");
        
    if([tk catalinaHomeChanged] || [tk catalinaBaseChanged]) {
        NSString *oldHome = 
            [tk catalinaHomeChanged]
            ? [tk _catalinaHome]
            : [tk catalinaHome];
        NSString *oldBase = 
            [tk catalinaBaseChanged]
            ? [tk _catalinaBase]
            : [tk catalinaBase];
        
        NSString *old = [self _hashForName:[tk name] home:oldHome base:oldBase];
        NSString *new = [self _hashForName:[tk name] home:[tk catalinaHome] base:[tk catalinaBase]];
        if(![old isEqualToString:new]) {
            [self _moveFilesForKitty:tk old:old new:new];
        }
    }

    // values 
    NSString *catalinaBase = 
        [tk catalinaBase] == nil
        ? @""
        : [tk catalinaBase];
    NSString *catalinaOpts = 
        [tk catalinaOpts] == nil
        ? @""
        : [tk catalinaOpts];
    NSString *program = 
        [NSString stringWithFormat:@"%@/bin/catalina.sh",[tk catalinaHome]];
    NSString *catOut = 
        [NSString stringWithFormat:@"%@/logs/catalina.out",[tk catalinaHome]];
    
    if([TCSLaunchDaemonManager didInstallACLs]) {
        id daemon = [self daemonForKitty:tk];
        // change EnvironmentVariables
        NSMutableDictionary *daemonEnv = [daemon objectForKey:@"EnvironmentVariables"];
        [daemonEnv setObject:[tk javaHome] forKey:TCSEnvKeyJavaHome];
        if([tk catalinaHome] != nil) {
            [daemonEnv setObject:[tk catalinaHome] forKey:TCSEnvKeyCatalinaHome];
        }
        if(catalinaBase != nil) {
            [daemonEnv setObject:catalinaBase forKey:TCSEnvKeyCatalinaBase];
        }
        if(catalinaOpts != nil) {
            [daemonEnv setObject:catalinaOpts forKey:TCSEnvKeyCatalinaOpts];
        }
        
        // change Program
        [daemon setObject:program forKey:TCSDaemonKeyProgram];

        // change StandardErrorPath
        [daemon setObject:catOut forKey:TCSDaemonKeyStandardErrorPath];

        // change StandardOutPath
        [daemon setObject:catOut forKey:TCSDaemonKeyStandardOutPath];

        [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
    }

    id agent = [self agentForKitty:tk];
    
    // change EnvironmentVariables
    NSMutableDictionary *agentEnv = [agent objectForKey:@"EnvironmentVariables"];
    logDebug(@"agentEnv = %@",agentEnv);
    logDebug(@"setting environment for kitty: %@",tk);
    [agentEnv setObject:[tk javaHome] forKey:TCSEnvKeyJavaHome];
    if([tk catalinaHome] != nil) {
        [agentEnv setObject:[tk catalinaHome] forKey:TCSEnvKeyCatalinaHome];
    }
    if(catalinaBase != nil) {
        [agentEnv setObject:catalinaBase forKey:TCSEnvKeyCatalinaBase];
    }
    if(catalinaOpts != nil) {
        [agentEnv setObject:catalinaOpts forKey:TCSEnvKeyCatalinaOpts];
    }
    //[agentEnv setObject:[tk catalinaHome] forKey:TCSEnvKeyCatalinaHome];
    //[agentEnv setObject:catalinaBase forKey:TCSEnvKeyCatalinaBase];
    //[agentEnv setObject:catalinaOpts forKey:TCSEnvKeyCatalinaOpts];
    
    // change Program
    [agent setObject:program forKey:TCSDaemonKeyProgram];

    // change StandardErrorPath
    [agent setObject:catOut forKey:TCSDaemonKeyStandardErrorPath];

    // change StandardOutPath
    [agent setObject:catOut forKey:TCSDaemonKeyStandardOutPath];
    
    [self _writePlist:agent forKitty:tk type:TCS_USER_LOGIN];
}

- (void) setRunPrivilegedForKitty:(TCSKitty *)tk {
    logDebug(@"setRunPrivilegedForKitty:");    
    if([TCSLaunchDaemonManager didInstallACLs]) {
        id daemon = [self daemonForKitty:tk];
        // change UserName
        NSString *userName = 
            [tk runPrivileged]
            ? @"root"
            :[[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
        
        [daemon setObject:userName forKey:TCSDaemonKeyUserName];
        [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
    }
}

- (void) setNameForKitty:(TCSKitty *)tk {
    NSString *old = [self _hashForName:[tk _name] home:[tk catalinaHome] base:[tk catalinaBase]];
    NSString *new = [self _hashForName:[tk name] home:[tk catalinaHome] base:[tk catalinaBase]];
    [self _moveFilesForKitty:tk old:old new:new];
    
    NSString *serviceDescription = [NSString stringWithFormat:@"%@ Tomcat Server",[tk name]];
    NSString *label = [NSString stringWithFormat:@"org.apache.tomcat.%@",[tk name]];
    if([TCSLaunchDaemonManager didInstallACLs]) {
        id daemon = [self daemonForKitty:tk];
        // change ServiceDescription
        [daemon setObject: serviceDescription forKey:TCSDaemonKeyServiceDescription];
        // change Label
        [daemon setObject: label forKey:TCSDaemonKeyLabel];
        [self _writePlist:daemon forKitty:tk type:TCS_SYSTEM_BOOT];
    }

    id agent = [self agentForKitty:tk];
    // change ServiceDescription
    [agent setObject:serviceDescription forKey:TCSDaemonKeyServiceDescription];
    // change Label
    [agent setObject:label  forKey:TCSDaemonKeyLabel];
    [self _writePlist:agent forKitty:tk type:TCS_USER_LOGIN];
}

- (id) daemonForKitty:(TCSKitty *)tk {
    id key = [self _plistPathForKitty:tk type:TCS_SYSTEM_BOOT];
    id daemon = [daemons objectForKey:key];
    if(daemon == nil) {
        daemon = [self _initPlistForKitty:tk type:TCS_SYSTEM_BOOT];
        [daemons setObject:daemon forKey:key];
    }
    logTrace(@"daemonForKitty: %@",daemon);
    return daemon;
}

- (id) agentForKitty:(TCSKitty *)tk {
    id key = [self _plistPathForKitty:tk type:TCS_USER_LOGIN];
    id agent = [agents objectForKey:key];
    if(agent == nil) {
        agent = [self _initPlistForKitty:tk type:TCS_USER_LOGIN];
        [agents setObject:agent forKey:key];
    }
    logTrace(@"agentForKitty: %@",agent);
    return agent;
}

/**
 * We track two layers of information about whether ACLs are installed:
 * The first is a preference that we set. The second is a test of the filesystem.
 * The first is historical and was in place before the fs test. When I added the
 * fs test I decided to keep the defaults test as a check of my c-programming skills ;-)
 * But I allow the fs check to override the defaults.
 */
+ (BOOL) didInstallACLs {
    logDebug(@"didInstallACLs");
    BOOL didInstall = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL defaultsSay = [defaults boolForKey:TCSUserDefaultsDidSetACLs];
    
    BOOL fileSystemSays = NO;
    const char *path =  [daemonPath fileSystemRepresentation];
    acl_t acls = acl_get_file(path, ACL_TYPE_EXTENDED);
    int validAcl = (acls != NULL ? acl_valid(acls) : -1) ;
    logDebug(@"validAcl = %d",validAcl);
    
    if(acls == NULL || validAcl != 0) {
        logError(@"No valid ACLS found at path:%@ (%s)",daemonPath,strerror(errno));
    } else {
        char *acls_text = acl_to_text(acls,NULL);
        // !#acl 1
        // user:7C82E6DC-D572-4283-A806-0D3797E9084E:johnclay:501:allow:write,delete_child
        logDebug(@"acls = %s",acls_text);

        // check for actual entry
        NSString *userName = [[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
        int uid = getuid();
        
        NSString *testString = [NSString stringWithFormat:@"%@:%d:allow:write,delete_child", userName,uid];
        NSString *entryString = [NSString stringWithUTF8String:acls_text];

        logDebug(@"%@.rangeOf:%@",entryString,testString);
        if([entryString rangeOfString:testString].location != NSNotFound) {
            fileSystemSays = YES;
        }
        acl_free(acls_text);
    }
    acl_free(acls);
    
    if(defaultsSay==YES && fileSystemSays==YES) {
        didInstall = YES;
    } else if(defaultsSay==NO) {
        if(fileSystemSays==YES)
            didInstall = YES;
    }
    return didInstall;
}


@end



@implementation TCSLaunchDaemonManager (Private)

- (id) _initPlistForKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type {
    logDebug(@"_initPlistForKitty:%@ type:%d",tk, type);
    id plist = nil;
    NSString *readfile = nil;
    NSString *writefile = [self _plistPathForKitty:tk type:type];
    
    NSError *err = nil;
    NSData *plistData;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:writefile];
    if(existed) {
        readfile = writefile;
    } else {
        switch (type) {
        case TCS_SYSTEM_BOOT:
            readfile = [[NSBundle mainBundle] 
                            pathForResource:@"daemon.template" ofType:@"plist"];
            break;
        case TCS_USER_LOGIN:
            readfile = [[NSBundle mainBundle] 
                            pathForResource:@"agent.template" ofType:@"plist"];
            break;
        default:
            break;
        }
    }
    
    NSURL *readurl = [NSURL fileURLWithPath:readfile];
    if (!readurl) {
        logError(@"Can't create an URL from readfile: %@", readfile);
        [NSException raise:TCSExceptionErrorReadingDaemonFile
                    format:@"Can't create an URL from readfile: %@", readurl];
    }
    
    if(existed) {
        plistData = [NSData dataWithContentsOfURL:readurl options:NSMappedRead error:&err];
    } else {
        
        NSMutableString *plistString = 
            [NSMutableString stringWithContentsOfURL:readurl encoding:NSUTF8StringEncoding error:&err];
       if(err) {
            [NSException raise:TCSExceptionErrorReadingDaemonFile
                        format:@"Could not create string from plist: %@ (%@)", readurl, err];
        }
        
        // replace tokens for initial values
        [plistString replaceOccurrencesOfString:@"{NAME}" 
                                     withString:([tk name] == nil ? @"" : [tk name])
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];
        
        [plistString replaceOccurrencesOfString:@"{JAVA_HOME}" 
                                     withString:([tk javaHome] == nil ? @"" : [tk javaHome])
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];
        
        [plistString replaceOccurrencesOfString:@"{CATALINA_HOME}" 
                                     withString:([tk catalinaHome] == nil ? @"" : [tk catalinaHome])
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];
        
        logTrace(@"tk.catalinaBase = %@",[tk catalinaBase]);
        [plistString replaceOccurrencesOfString:@"{CATALINA_BASE}" 
                                     withString:([tk catalinaBase] == nil ? @"" : [tk catalinaBase])
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];
        

        logTrace(@"tk.catalinaOpts = %@",[tk catalinaOpts]);
        logTrace(@"tk.catalinaOpts==nil: %d",([tk catalinaOpts] == nil));
        [plistString replaceOccurrencesOfString:@"{CATALINA_OPTS}" 
                                     withString:([tk catalinaOpts] == nil ? @"" : [tk catalinaOpts])
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];

        NSString *userName = [[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
        logTrace(@"userName = %@",userName);
        [plistString replaceOccurrencesOfString:@"{USER}" 
                                     withString:userName 
                                        options:0 
                                          range:NSMakeRange(0,[plistString length])];

        logTrace(@"plistString = %@",plistString); 
        plistData = [plistString dataUsingEncoding:NSUTF8StringEncoding];
       
    }
    
    NSString *errMsg = nil;
    plist = (id)CFPropertyListCreateFromXMLData(kCFAllocatorDefault,
                                                (CFDataRef)plistData, kCFPropertyListMutableContainersAndLeaves,
                                                (CFStringRef *)&errMsg);
    if(plist == nil || errMsg) {
        [NSException raise:TCSExceptionErrorReadingDaemonFile
                    format:@"Could not initialize daemon from plist: %@ (%@)", readurl, errMsg];
    }
    return [plist autorelease];
}

- (id) _writePlist:(id)plist forKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type {
    
    // create ~/LaunchAgents if needed
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fullAgentPath = [agentPath stringByExpandingTildeInPath];
    BOOL agentDirExists;
    if(!(agentDirExists = [fm fileExistsAtPath:fullAgentPath])) {
        BOOL setupAgentsDir = [fm createDirectoryAtPath:[agentPath stringByExpandingTildeInPath] attributes:nil];
        logDebug(@"Successfully initialized agents dir = %d",setupAgentsDir);
    }
    logDebug(@"agentDirExists = %d",agentDirExists);
    
    
    NSString *plistPath = [self _plistPathForKitty:tk type:type];
    BOOL success = [plist writeToFile:plistPath atomically:YES];

    if(!success) {
        logError(@"Could not write plist %@ to file: %@ - trying again",  plist, plistPath);
        success = [plist writeToFile:plistPath atomically:YES];
        logError(@"Could not write to plist file a second time: %@", plistPath);
    }
    if(!success) {
        [NSException raise:TCSExceptionErrorWritingToDaemonFile 
                    format:@"Could not write to plist file: %@", plistPath];
    }
}

- (void) _moveFilesForKitty:(TCSKitty *)tk old:(NSString *)old new:(NSString *)new {
    NSString *oldPath = [self _plistPathForKitty:tk type:TCS_SYSTEM_BOOT basename:old];
    NSString *newPath = [self _plistPathForKitty:tk type:TCS_SYSTEM_BOOT basename:new];

    if([TCSLaunchDaemonManager didInstallACLs]) {
        // move daemon file        
        NSTask *mvDaemon = [[NSTask alloc] init];
        NSPipe *mvDaemonOutPipe = [NSPipe pipe];
        NSPipe *mvDaemonInPipe = [NSPipe pipe]; 
        if(mvDaemonOutPipe == nil || mvDaemonInPipe == nil) {
            logError(@"Error creating pipe (%s)",strerror(errno));
            return;
        }
        NSFileHandle *mvDaemonReadHandle = [mvDaemonOutPipe fileHandleForReading];
        NSMutableData *mvDaemonInData = [NSMutableData data];
        
        [mvDaemon setLaunchPath:@"/bin/mv"];
        
        [mvDaemon setArguments:[NSArray arrayWithObjects:oldPath, newPath, nil]];        
        
        [mvDaemon setStandardInput:mvDaemonInPipe];
        [mvDaemon setStandardOutput:mvDaemonOutPipe];
        [mvDaemon setStandardError:mvDaemonOutPipe];
        
        logDebug(@"mv %@ %@",oldPath, newPath);
        
        [mvDaemon launch];
        
        [TCSIOUtils readIntoData:mvDaemonInData fromHandle:mvDaemonReadHandle];
        logDebug(@"mvDaemon.out = { %@ }",[TCSIOUtils dataString:mvDaemonInData]);
        
        [mvDaemon release];
    }

    // mv agent file
    oldPath = [self _plistPathForKitty:tk type:TCS_USER_LOGIN basename:old];
    newPath = [self _plistPathForKitty:tk type:TCS_USER_LOGIN basename:new];

    NSTask *mvAgent = [[NSTask alloc] init];
    NSPipe *mvAgentOutPipe = [NSPipe pipe];
    NSPipe *mvAgentInPipe = [NSPipe pipe]; 
    if(mvAgentOutPipe == nil || mvAgentInPipe == nil) {
        logError(@"Error creating pipe (%s)",strerror(errno));
        return;
    }
    NSFileHandle *mvAgentReadHandle = [mvAgentOutPipe fileHandleForReading];
    NSMutableData *mvAgentInData = [NSMutableData data];
    
    [mvAgent setLaunchPath:@"/bin/mv"];
    
    [mvAgent setArguments:[NSArray arrayWithObjects:oldPath, newPath, nil]];        
    
    [mvAgent setStandardInput:mvAgentInPipe];
    [mvAgent setStandardOutput:mvAgentOutPipe];
    [mvAgent setStandardError:mvAgentOutPipe];
    
    logDebug(@"mv %@ %@",oldPath, newPath);
    
    [mvAgent launch];
    
    [TCSIOUtils readIntoData:mvAgentInData fromHandle:mvAgentReadHandle];
    logDebug(@"mvAgent.out = { %@ }",[TCSIOUtils dataString:mvAgentInData]);
    
    [mvAgent release];
}

- (NSString *) _plistPathForKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type { 
    return [self _plistPathForKitty:tk type:type basename:[self _nameHashForKitty:tk]];
}

- (NSString *) _plistPathForKitty:(TCSKitty *)tk 
                             type:(TCSAutomaticStartupType)type 
                         basename:(NSString *)basename {
    NSString *plistPath = nil;
    switch (type) {
        case TCS_NEVER:
            [NSException raise:TCSExceptionInvalidDaemonFile
                        format:@"No single file associated with this startup type"];
            break;            
        case TCS_SYSTEM_BOOT:
            plistPath = daemonPath;
            break;
        case TCS_USER_LOGIN:
            plistPath = agentPath;
            break;
        default:
            break;
    }
    logDebug(@"plistPath = %@",plistPath);
    plistPath = [plistPath stringByAppendingFormat:@"%@.plist",basename];
    plistPath = [plistPath stringByExpandingTildeInPath];
    logDebug(@"plist path for type %d: %@",type,plistPath);
    return plistPath;
}

- (NSString *) _nameHashForKitty:(TCSKitty *)tk {
    NSString *name = [[tk name] lastPathComponent];
    NSString *home = [tk catalinaHome];
    NSString *base = [tk catalinaBase];
    return [self _hashForName:name home:home base:base];
}

- (NSString *) _hashForName:(NSString *)name home:(NSString *)home base:(NSString *)base {
    NSString *nameHash = nil;
    if(base != nil && ![base isEqualToString:home]) {
        nameHash = [NSString stringWithFormat:@"%@-%X%X"
            , name
            , [home hash]
            , [base hash]];
    } else {
        nameHash = [NSString stringWithFormat:@"%@-%X"
            , name
            , [home hash]];
    }
    return nameHash;
}


- (void) _enableACLs:(AuthorizationRef)authRef {
    OSStatus authStatus;
    
    FILE *fsaclctlPipe = NULL;        
    char *fsaclctlArgs[4];
    fsaclctlArgs[0] = "-p";
    fsaclctlArgs[1] = "/";
    fsaclctlArgs[2] = "-e";
    fsaclctlArgs[3] = NULL;
    logDebug(@"running fsaclctl:%s withArgs:%s"
             ,[fsaclctlCommand fileSystemRepresentation]
             ,fsaclctlArgs);
    
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
    authStatus =  
        AuthorizationExecuteWithPrivileges(authRef,
                                           [fsaclctlCommand fileSystemRepresentation],
                                           authFlags,
                                           fsaclctlArgs,
                                           &fsaclctlPipe); 
    if (authStatus != errAuthorizationSuccess) {
        logError(@"Could not authorize fsaclctl:%d",authStatus);
        [NSException raise:TCSExceptionCouldNotEnableACLs
                    format:@"There was an error installing Access Control Lists (Could not authorize fsaclctl:%d)",authStatus];
    }  else {
        [TCSIOUtils _readPipe:fsaclctlPipe];
        int pid;
        int status;
        pid = wait(&status);
        logDebug(@"pid = %d",pid);
        logDebug(@"status = %d",status);
        logDebug(@"clean exit: %d",WIFEXITED(status));
        if(pid == -1 || ! WIFEXITED(status) || status > 0) {
            logError(@"fsaclctl did not exit cleanly: %d",status);
            [NSException raise:TCSExceptionCouldNotEnableACLs
                        format:@"There was an error installing Access Control Lists (fsaclctl did not exit cleanly: %d)",status];
        }
    }
}

- (void) _addACLEntry:(AuthorizationRef)authRef {
    //chmod +a "johnclay allow add_file,delete_child" LaunchDaemons
    NSString *userName = [[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
    OSStatus authStatus;
    
    FILE *chmodPipe = NULL;        
    char *chmodArgs[4];
    chmodArgs[0] = "+a";
    chmodArgs[1] = (char *) [[NSString stringWithFormat:@"%@ allow add_file,delete_child",userName] cString];
    chmodArgs[2] = (char *) [daemonPath cString];
    chmodArgs[3] = NULL;
    logDebug(@"running chmod:%s withArgs:%@"
             ,[chmodCommand fileSystemRepresentation]
             ,[NSString stringWithFormat:@"%s %s %s",chmodArgs[0],chmodArgs[1],chmodArgs[2]]);
    
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
    authStatus =  
        AuthorizationExecuteWithPrivileges(authRef,
                                           [chmodCommand fileSystemRepresentation],
                                           authFlags,
                                           chmodArgs,
                                           &chmodPipe); 
    if (authStatus != errAuthorizationSuccess) {
        logError(@"Could not authorize chmod:%d",authStatus);
        [NSException raise:TCSExceptionCouldNotAddACLEntry
                    format:@"There was an error adding an ACL entry (Could not authorize chmod:%d)",authStatus];
    }  else {
        [TCSIOUtils _readPipe:chmodPipe];
        int pid;
        int status;
        pid = wait(&status);
        logDebug(@"pid = %d",pid);
        logDebug(@"status = %d",status);
        logDebug(@"clean exit: %d",WIFEXITED(status));
        if(pid == -1 || ! WIFEXITED(status) || status > 0) {
            logError(@"chmod did not exit cleanly: %d",status);
            [NSException raise:TCSExceptionCouldNotAddACLEntry
                        format:@"There was an error adding an ACL entry (chmod did not exit cleanly: %d)",status];
        }
    }
}


@end
