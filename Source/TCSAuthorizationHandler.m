//
//  TCSAuthorizationHandler.m
//  TomcatSlapper
//
//  Created by John Clayton on 6/28/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSAuthorizationHandler.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import <AGRegex/AGRegex.h>

@implementation TCSAuthorizationHandler


static TCSAuthorizationHandler *handler;


// OBJECT STUFF ============================================================= //

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super init]) {
        authRef = NULL;
    }
    return self;
}

- (void) dealloc {
    [self deauthorize];
    [super dealloc];
}


// SINGLETON AUTH HANDLER =================================================== //

+ (id) sharedAuthHandler {
    if(handler == nil) {
        handler = [[TCSAuthorizationHandler alloc] _init];
    }
    return handler;
}

- (BOOL) isAuthorized {
    logDebug(@"authorizing");
    BOOL authorized = NO;
    OSStatus authStatus = errAuthorizationSuccess;
    
    //create empty authRef
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
    @synchronized(self) {
        if(authRef == NULL) {
            authStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
                                             authFlags, &authRef); 
        }
        if(authStatus == errAuthorizationSuccess) {
            AuthorizationItem authItems = {kAuthorizationRightExecute, 0, NULL, 0}; 
            AuthorizationRights authRights = {1, &authItems}; 
            authFlags = kAuthorizationFlagDefaults | 
                kAuthorizationFlagInteractionAllowed | 
                kAuthorizationFlagPreAuthorize | 
                kAuthorizationFlagExtendRights; 
            authStatus = AuthorizationCopyRights (authRef, &authRights
                                                  , kAuthorizationEmptyEnvironment
                                                  , authFlags, NULL );
            authorized = (authStatus == errAuthorizationSuccess);
        } 
    }
    return authorized;
}

- (AuthorizationRef) authorization {
    return authRef;
}

- (void) deauthorize {
    if(authRef != NULL) {
        AuthorizationFree(authRef,kAuthorizationFlagDefaults);
        authRef = NULL;
    }
}

- (void) alertUser:(OSStatus) status {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:NSLocalizedString(@"TCSAuthorizationController.authorizationWarningMessage",nil)];
    NSString *info = [NSString stringWithFormat:
        NSLocalizedString(@"TCSAuthorizationController.authorizationWarningInfo",nil)
        ,status];
    [alert setInformativeText:info];
    [alert setShowsHelp:NO];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    int retval = [alert runModal];
}

@end

OSStatus runVerifiedTool(AuthorizationRef authorization,
                         const char *pathToTool,
                         AuthorizationFlags options,
                         char * const *arguments,
                         FILE **communicationsPipe, 
                         const char *sum) 
{
    OSStatus authStatus = 0;
    authStatus = verified(pathToTool,sum);
    logDebug(@"authStatus = %d",authStatus);
    if(authStatus == errAuthorizationSuccess) {
        @try {
            authStatus =  
                AuthorizationExecuteWithPrivileges(authorization,
                                                   pathToTool,
                                                   options,
                                                   arguments,
                                                   communicationsPipe);
        }
        @catch (NSException * e) {
            logError(@"Error running verified tool:%s (%@)",pathToTool,[e description]);
            authStatus =  errAuthorizationToolExecuteFailure;
        }
    }
    return authStatus;
}

OSStatus verified(const char *pathToTool, const char *sum)
{
    // trying to force filehandles to close
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPipe *outPipe = [[NSPipe alloc] init];
    if(outPipe == nil) {
        logError(@"Error creating pipe for md5 check (%s)",strerror(errno));
        return errAuthorizationToolExecuteFailure;
    }
    NSString *found;
    NSString *expect;
    @try {
        expect = [NSString stringWithUTF8String:sum];
        
        NSString *path = [NSString stringWithUTF8String:pathToTool];
        NSTask *verifier = [[NSTask alloc] init];
        NSFileHandle *readHandle = [outPipe fileHandleForReading];
        NSMutableData *inData = [NSMutableData data];
        
        [verifier setCurrentDirectoryPath:NSHomeDirectory()];
        [verifier setLaunchPath:@"/sbin/md5"];
        [verifier setArguments:[NSArray arrayWithObjects:@"-q",path,nil]];        
        [verifier setStandardOutput:outPipe];
        [verifier setStandardError:outPipe];
        [verifier launch];
        
        [TCSIOUtils readIntoData:inData fromHandle:readHandle];
        
        found = 
            [[TCSIOUtils dataString:inData] 
                stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [outPipe release];
        [verifier release]; // why release here?
    
    } @catch (NSException * e) {
        logError(@"Error running md5 check (%@)",[e description]);
        return errAuthorizationToolExecuteFailure;
    }
    
    logDebug(@"found,expect (%@,%@)", found,expect);    
    logDebug(@"found=expect:%d",[found isEqualToString:expect]);
    OSStatus verified =  ([found isEqualToString:expect]
            ? errAuthorizationSuccess
            : errAuthorizationToolExecuteFailure
            );
    //[pool release];
    return verified;
     
//    return errAuthorizationSuccess;
}
