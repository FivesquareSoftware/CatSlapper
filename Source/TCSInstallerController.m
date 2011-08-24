//
//  TCSInstallerController.m
//  TomcatSlapper
//
//  Created by John Clayton on 4/30/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSInstallerController.h"
#import "TCSInstallerController+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSKitty.h"
#import "TCSCatWrangler.h"
#import "TCSIOUtils.h";
#import <AGRegex/AGRegex.h>
#import "TCSAuthorizationHandler.h"

@implementation TCSInstallerController

static TCSInstallerController *controller;


// OBJECT STUFF ============================================================= //
#pragma mark Object Methods

+ (void) initialize {
    [self setKeys:[NSArray arrayWithObjects:@"isInstalling",nil] 
            triggerChangeNotificationsForDependentKey:@"validConfiguration"];    
}

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (void) dealloc {
    [kitty release];
    [stdErrFilePath release];
    [taskStdErrHandle release];
    [installerPath release];
    [self removeObservations];
    [super dealloc];    
}

- (void) awakeFromNib {
    [self registerObservations];
    installerPath = 
        [[[NSBundle mainBundle] 
            pathForResource:@"install-5.0.28" 
                     ofType:@"sh" 
                inDirectory:@"Installer"] retain];
    
    [progressBar setUsesThreadedAnimation:YES];
}

// SINGLETON INSTALLER CONTROLLER =========================================== //
#pragma mark Singleton

+ (TCSInstallerController *) sharedInstallerController {
    if(controller == nil) {
        controller = [[TCSInstallerController alloc] _init];
        [controller window]; //loads nib
    }
    return controller;
}

// ACTIONS ================================================================== //
#pragma mark Actions

- (IBAction) install:(id)sender {
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isInstalling"];
    count = 0;
    [progressBar setDoubleValue:0.00];
    [progressBar startAnimation:self];
    [messages selectAll:self];
    [messages delete:self];
    [NSThread detachNewThreadSelector:@selector(_authorizedInstall:) 
                             toTarget:self 
                           withObject:kitty];
}

- (IBAction) displayInstallerHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpInstallerAnchor
                    inBook:TCSCatSlapperHelpBook];
}

- (IBAction) browse:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setAllowsMultipleSelection:NO];
    [op setCanCreateDirectories:YES];
    [op setPrompt:@"Choose"];
    //it's bizarre that I should have to retain this, the panel should do it
    NSNumber *picking = [[NSNumber numberWithInt:[sender tag]] retain];
    [op  beginSheetForDirectory:nil
                           file:nil
                          types:nil
                 modalForWindow:[self window]
                  modalDelegate:self
                 didEndSelector:@selector(browseDidEnd:returnCode:contextInfo:)
                    contextInfo:picking
        ];
}

- (void) browseDidEnd:(NSOpenPanel *)sheet 
           returnCode:(int)returnCode 
          contextInfo:(void  *)contextInfo {
    //user cancelled
    if(returnCode != NSOKButton) return;
    
    NSNumber *picked = (NSNumber *)contextInfo;
    NSString *filename = [[sheet filenames] objectAtIndex:0];
    switch([picked intValue]) {
        case 0: 
            [installingKittyController setValue:filename forKeyPath:@"selection.javaHome"];
            break;
        case 1: 
            [installingKittyController setValue:filename forKeyPath:@"selection.catalinaHome"];
            break;
        case 2: 
            [installingKittyController setValue:filename forKeyPath:@"selection.catalinaBase"];
            break;
        default: break;
    }
    [picked release];
}

- (IBAction) editOpts:(id)sender {
    [entryWin setTitle:@"CATALINA_OPTS"];
    [entryField setStringValue:[catalinaOptsField stringValue]];
    [entryWin makeKeyAndOrderFront:self];
}

- (IBAction) didEndEditOpts:(id)sender {
    [installingKittyController setValue:[entryField stringValue] forKeyPath:@"selection.catalinaOpts"];
    [entryWin performClose:self];
}


- (BOOL) validConfiguration {
    BOOL valid = YES;
    if(isInstalling) {
        valid = NO;
    } else if(kitty != nil) {
        NSString *javaHome = [kitty javaHome];
        NSString *catalinaHome = [kitty catalinaHome];
        NSString *catalinaBase = [kitty catalinaBase];
        NSString *shutdownPort = [kitty shutdownPort];
        NSString *defaultHttpPort = [kitty defaultHttpPort];
        NSString *defaultAjpPort = [kitty defaultAjpPort];

        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir;
        AGRegex *nonDigitRegex = [AGRegex regexWithPattern:@"[^\\d]"];
        
        //validate JAVA_HOME
        if(javaHome != nil && ![javaHome isEqualToString:@""]) {
            NSString *javaJRE = [javaHome stringByAppendingPathComponent:TCSJavaJRE];
            if(![fm fileExistsAtPath:javaHome isDirectory:&isDir] 
               || !isDir
               || ![fm fileExistsAtPath:javaJRE]) {
                valid = NO;
            }
        }
        //catalina home is required
        if(catalinaHome == nil || [catalinaHome isEqualToString:@""]) {
            valid = NO;
        }
        if(shutdownPort == nil || [shutdownPort isEqualToString:@""]) {
            valid = NO;
        } else {
            //validate as integers only
            if([nonDigitRegex findInString:shutdownPort] != nil) valid = NO;
        }
        if(defaultHttpPort == nil || [defaultHttpPort isEqualToString:@""]) {
            valid = NO;
        } else {
            //validate as integers only
            if([nonDigitRegex findInString:defaultHttpPort] != nil) valid = NO;
        }
        if(defaultAjpPort == nil || [defaultAjpPort isEqualToString:@""]) {
            valid = NO;
        } else {
            //validate as integers only
            logDebug(@"defaultAjpPort = %@",defaultAjpPort);
            if([nonDigitRegex findInString:defaultAjpPort] != nil) valid = NO;
        }
    }
    return valid;
}


// SAVE PANEL DELEGATE ====================================================== //

- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename {
    logDebug(@"isValidFilename:%@",filename);
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL valid, isDir = [fm fileExistsAtPath:filename isDirectory:&isDir];
    return (valid && isDir);
}



// KVC ====================================================================== //
#pragma mark KVC

/*
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic;
    if ([theKey isEqualToString:@"validConfiguration"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}
*/
- (TCSKitty *)kitty {
    return kitty;
}

- (void)setKitty:(TCSKitty *)newKitty {
    [newKitty retain];
    [kitty release];
    kitty = newKitty;
}

- (NSString *)stdErrFilePath {
    return stdErrFilePath;
}

- (void)setStdErrFilePath:(NSString *)newStdErrFilePath {
    logTrace(@"setStdErrFilePath:%@",newStdErrFilePath);
    [newStdErrFilePath retain];
    [stdErrFilePath release];
    stdErrFilePath = newStdErrFilePath;
}

- (NSFileHandle *)taskStdErrHandle {
    return taskStdErrHandle;
}

- (void)setTaskStdErrHandle:(NSFileHandle *)newTaskStdErrHandle {
    [newTaskStdErrHandle retain];
    [taskStdErrHandle release];
    taskStdErrHandle = newTaskStdErrHandle;
}

- (NSString *)managerUser {
    return managerUser;
}

- (void)setManagerUser:(NSString *)newManagerUser {
    [newManagerUser retain];
    [managerUser release];
    managerUser = newManagerUser;
}

- (NSString *)managerPasswd {
    return managerPasswd;
}

- (void)setManagerPasswd:(NSString *)newManagerPasswd {
    [newManagerPasswd retain];
    [managerPasswd release];
    managerPasswd = newManagerPasswd;
}



// WINDOW CONTROLLER ======================================================== //
#pragma mark Window Controller

- (void) showWindow:(id)sender {
    [self _initKitty];
    isInstalling = NO;    
    [super showWindow:sender];
}

- (void) close {
    [super close];
}


// WINDOW DELEGATE ========================================================== //
#pragma mark Window Delegate

- (BOOL) windowShouldClose:(id)sender {
    if(isInstalling) return NO;
    
    logDebug(@"windowShouldClose:%@",sender);
    NSMenuItem *viewItem = [[NSApp mainMenu] itemWithTitle:@"View"];
//    logDebug(@"viewItem = %@",viewItem);
    NSMenu *viewMenu = [viewItem submenu];
//    logDebug(@"viewMenu = %@",viewMenu);
    NSMenuItem *installerItem = [viewMenu itemWithTitle:@"Installer"];
//    logDebug(@"installerItem = %@",installerItem);
    [installerItem setState:NSOffState];
    [self close];
    return NO;
}



// OBSERVATIONS ============================================================= //
#pragma mark Observations

- (void) registerObservations {
    [installingKittyController addObserver:self
                      forKeyPath:@"selection.javaHome" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [installingKittyController addObserver:self
                      forKeyPath:@"selection.catalinaHome" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [installingKittyController addObserver:self
                      forKeyPath:@"selection.catalinaBase" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [installingKittyController addObserver:self
                      forKeyPath:@"selection.catalinaOpts" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [installingKittyController addObserver:self
                                forKeyPath:@"selection.defaultHttpPort" 
                                   options:(NSKeyValueObservingOptionNew |
                                            NSKeyValueObservingOptionOld)
                                   context:NULL];    
    [installingKittyController addObserver:self
                                forKeyPath:@"selection.defaultAjpPort" 
                                   options:(NSKeyValueObservingOptionNew |
                                            NSKeyValueObservingOptionOld)
                                   context:NULL];    
}

- (void) removeObservations {
    [installingKittyController removeObserver:self forKeyPath:@"selection.javaHome"];    
    [installingKittyController removeObserver:self forKeyPath:@"selection.catlinaHome"];    
    [installingKittyController removeObserver:self forKeyPath:@"selection.catlinaBase"];    
    [installingKittyController removeObserver:self forKeyPath:@"selection.catlinaOpts"];    
    [installingKittyController removeObserver:self forKeyPath:@"selection.defaultHttpPort"];    
    [installingKittyController removeObserver:self forKeyPath:@"selection.defaultAjpPort"];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    logDebug(@"observeValueForKeyPath: %@",keyPath);
    [self willChangeValueForKey:@"validConfiguration"];
    [self didChangeValueForKey:@"validConfiguration"];
}

- (NSAttributedString *) errorString:(NSString *)errorString {
    NSMutableAttributedString *attributedErrorString = 
        [[NSMutableAttributedString alloc] 
                    initWithString:errorString];
    [attributedErrorString 
        addAttribute:NSForegroundColorAttributeName 
               value:[NSColor redColor]  
               range:NSMakeRange(0,[attributedErrorString length])];
    [attributedErrorString 
        appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    return attributedErrorString;
}

@end


@implementation TCSInstallerController (Private)

- (void) _tmuClr {
    [self setManagerUser:@""];
}

- (void) _tmpClr {
    [self setManagerPasswd:@""];
}

- (id) _init {
    if(self = [super initWithWindowNibName:@"Installer"]) {
        ticks = 16;
        count = 0;
    }
    return self;
}

- (void) _initKitty {
    [self setKitty:[[TCSKitty alloc] init]];
    [kitty setName:@"Install Another Rascally Cat"];
    [kitty setShutdownPort:[self _incrementPort:TCSTomcatDefaultShutdownPort]];
    [kitty setDefaultHttpPort:[self _incrementPort:TCSTomcatDefaultHttpPort]];
    [kitty setDefaultAjpPort:[self _incrementPort:TCSTomcatDefaultAjpPort]];
    [installingKittyController remove:self];
    [installingKittyController setContent:[self kitty]];
    [self _tmuClr];
    [self _tmpClr];
//    [[[self window] contentView] setNeedsDisplay:YES];
}

- (NSString *) _incrementPort:(NSString *)port {
    int pnum = [port intValue];
    int kcount = [self _kittyCount];
    logDebug(@"pnum = %d",pnum);
    logDebug(@"kcount = %d",kcount); 
    return [NSString stringWithFormat:@"%d",(pnum+(100*kcount))];
}

- (int) _kittyCount {
    int kcount = 0;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    //read from user defaults
    NSData *kittensAsData = [defs dataForKey:TCSUserDefaultsKittens];  
    if(kittensAsData != nil) {
        kcount = [[NSKeyedUnarchiver unarchiveObjectWithData:kittensAsData] count];
    }    
    return kcount;
}

- (void) _authorizedInstall:(TCSKitty *)tk {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TCSAuthorizationHandler *authHandler = [TCSAuthorizationHandler sharedAuthHandler];
    if([authHandler isAuthorized]) {
        OSStatus authStatus;

        [self _generateStdErrHandle];
        FILE *installerPipe = NULL;
        NSMutableArray *argsArray = [self _installerArgsForKitty:tk];
        [argsArray addObject:@"-d"];
        [argsArray addObject:
            [[NSBundle mainBundle] pathForResource:@"Installer" ofType:nil]];

        char *installerArgs[[argsArray count]+1];
        int i;
        for(i = 0; i < [argsArray count]; i++) {
            installerArgs[i] = (char *)[[argsArray objectAtIndex:i] cString];
        }
            installerArgs[[argsArray count]] = NULL;
        
        logDebug(@"running installer:%s withArgs:%@"
                 ,[installerPath fileSystemRepresentation]
                 ,argsArray);
        
#ifndef INSTALLER_MD5_SUM
#warning "** WARNING ** INSTALLER_MD5_SUM NOT DEFINED!"
#endif
        const char *sum = INSTALLER_MD5_SUM;
        AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
        authStatus = runVerifiedTool([authHandler authorization]
                                     , [installerPath fileSystemRepresentation]
                                     , authFlags
                                     , installerArgs
                                     , &installerPipe
                                     , sum); 

        if (authStatus != errAuthorizationSuccess) {
            logError(@"Could not authorize installer:%d",authStatus);
            // TODO alert user of problem
            [authHandler alertUser:authStatus];
        }  else {
            [self _readInstallerOut:installerPipe];
            int pid;
            int status;
            pid = wait(&status);
            logDebug(@"status = %d",status);
            logDebug(@"clean exit: %d",WIFEXITED(status));
            if(pid == -1 || ! WIFEXITED(status) || status > 0) {
                logError(@"Installer task did not exit cleanly: %d",status);
                [messages insertText:@"\n"];
                [messages insertText:
                    [self errorString:
                        NSLocalizedString(@"TCSInstallerController.installFailed",nil)]
                    ];
            } else {
                logDebug(@"installing kitty with port:%@",[kitty defaultHttpPort]);
                NSNotification *note = 
                    [NSNotification 
                        notificationWithName:TCSNotifcationTomcatInstalled object:tk];
                [[NSNotificationCenter defaultCenter] postNotification:note];
                logDebug(@"blanking kitty:%@",kitty);
                [self _initKitty];
                logDebug(@"kitty = %@",kitty);
            }
        }
        logDebug(@"reading errors");
        NSData *errData = [taskStdErrHandle readDataToEndOfFile];
        [messages insertText:[self errorString:[TCSIOUtils dataString:errData]]];    
        [taskStdErrHandle closeFile];
        [[NSFileManager defaultManager] removeFileAtPath:stdErrFilePath handler:NULL];
        
        logDebug(@"resetting progress");
        [self setValue:[NSNumber numberWithBool:NO] forKey:@"isInstalling"];
        [progressBar setDoubleValue:0.00];
        [progressBar stopAnimation:self];
        
    }
    [pool release];
}

- (void) _generateStdErrHandle {
    [self setStdErrFilePath:
            [NSString stringWithFormat:@"/tmp/catslapper.%u.%u.errors"
                , getpid(), random()]];
    [[NSFileManager defaultManager] createFileAtPath:stdErrFilePath 
                                            contents:nil attributes:nil];

    [self setTaskStdErrHandle:[NSFileHandle fileHandleForReadingAtPath:stdErrFilePath]];
    logTrace(@"taskStdErrHandle:%@",taskStdErrHandle);
}

- (NSMutableArray *) _installerArgsForKitty:(TCSKitty *)tk {
    NSMutableArray *argsArray = [NSMutableArray array];
    
    [argsArray addObject:@"-e"];
    [argsArray addObject:stdErrFilePath];
    
    [argsArray addObject:@"-h"];
    [argsArray addObject:[tk catalinaHome]];
    
    if([tk catalinaBase] != nil) {
        [argsArray addObject:@"-b"];
        [argsArray addObject:[tk catalinaBase]];
    }
    if([tk shutdownPort] != nil && ![[tk shutdownPort] isEqualToString:TCSTomcatDefaultShutdownPort]) {
        [argsArray addObject:@"-s"];
        [argsArray addObject:[tk shutdownPort]];
    }
    if([tk defaultHttpPort] != nil && ![[tk defaultHttpPort] isEqualToString:TCSTomcatDefaultHttpPort]) {
        [argsArray addObject:@"-t"];
        [argsArray addObject:[tk defaultHttpPort]];
    }
    if([tk defaultAjpPort] != nil && ![[tk defaultAjpPort] isEqualToString:TCSTomcatDefaultAjpPort]) {
        [argsArray addObject:@"-q"];
        [argsArray addObject:[tk defaultAjpPort]];
    }
    if(managerUser != nil) {
        [argsArray addObject:@"-u"];
        [argsArray addObject:managerUser];
    }
    if(managerPasswd != nil) {
        [argsArray addObject:@"-p"];
        [argsArray addObject:managerPasswd];
    }
    
    return argsArray;
}

- (void) _readInstallerOut:(FILE *)installerPipe {
    char myReadBuffer[128]; 
    @try {
        for(;;) {
            int bytesRead = read (fileno (installerPipe),
                                  myReadBuffer, sizeof (myReadBuffer));
            if (bytesRead < 1) break;
            
            if(count++ > ticks) count = ticks;
            double value = ((100.00 * count) / ticks);
            [progressBar setDoubleValue:value];
            NSData *outData = [NSData dataWithBytes:myReadBuffer length:bytesRead];
            NSString *msg = [TCSIOUtils dataString:outData];
            logDebug(@"msg = %@",msg);
            @synchronized(self) {
                [messages insertText:msg];
            }
        }
    } @catch(NSException *e) {
        logError(@"There was a problem reading installer out: %@",[e description]);
    } @finally {
        fflush(installerPipe);
        fclose(installerPipe);
    }
}

@end


