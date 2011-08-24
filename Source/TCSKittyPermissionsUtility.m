//
//  TCSKittyPermissionsUtility.m
//  TomcatSlapper
//
//  Created by John Clayton on 2/11/06.
//  Copyright 2006 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSKittyPermissionsUtility.h"
#import "TCSKittyPermissionsUtility+Private.h"
#import "TCSLogger.h"
#import "TCSKitty.h"
#import "TCSAuthorizationHandler.h"
#import "TCSIOUtils.h"


static NSString *chownCommand = @"/usr/sbin/chown";
static NSString *chmodCommand = @"/bin/chmod";


@implementation TCSKittyPermissionsUtility

+ (BOOL) kittyPermissionsNeedRepair:(TCSKitty *)tk {
    logDebug(@"kittyPermissionsNeedRepair: %@",tk);
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL needRepair = NO;
    // check pid
    if(![fm isWritableFileAtPath:[tk catalinaPid]]) {
        needRepair = YES;
    } else if(![fm isWritableFileAtPath:[tk logfile]]) { // check logfile
        needRepair = YES;
    }
    return needRepair;
}

+ (void) repairPermissionsForKitty:(TCSKitty *)tk {
    logDebug(@"repairPermissionsForKitty: %@",tk);
    TCSAuthorizationHandler *authHandler = [TCSAuthorizationHandler sharedAuthHandler];
    if([authHandler isAuthorized]) {
        [self _repairDirectory:[tk catalinaHome] withAuthorization:[authHandler authorization]];
        // repair logs
    } else {
        logError(@"Not authorized to repair permissions");
        [NSException raise:TCSExceptionCouldNotRepairPermissions
                    format:@"Not authorized to repair permissions"];
    }
    
}

+ (void) _repairDirectory:(NSString *)directoryPath withAuthorization:(AuthorizationRef)authRef {
    NSString *userName = [[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
    OSStatus authStatus;
    
    FILE *chownPipe = NULL;        
    char *chownArgs[4];
    chownArgs[0] = "-R";
    chownArgs[1] = (char *) [[NSString stringWithFormat:@"%@:admin",userName] cString];
    chownArgs[2] = (char *) [directoryPath cString];
    chownArgs[3] = NULL;
    logDebug(@"running chown:%s withArgs:%@"
             ,[chownCommand fileSystemRepresentation]
             ,[NSString stringWithFormat:@"%s %s %s",chownArgs[0],chownArgs[1],chownArgs[2]]);
    
    AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
    authStatus =  
        AuthorizationExecuteWithPrivileges(authRef,
                                           [chownCommand fileSystemRepresentation],
                                           authFlags,
                                           chownArgs,
                                           &chownPipe); 
    if (authStatus != errAuthorizationSuccess) {
        logError(@"Could not authorize chown:%d",authStatus);
        [NSException raise:TCSExceptionCouldNotRepairPermissions
                    format:@"There was an error repairing directory permissions (Could not authorize chown:%d)",authStatus];
    }  else {
        [TCSIOUtils _readPipe:chownPipe];
        int pid;
        int status;
        pid = wait(&status);
        logDebug(@"pid = %d",pid);
        logDebug(@"status = %d",status);
        logDebug(@"clean exit: %d",WIFEXITED(status));
        if(pid == -1 || ! WIFEXITED(status) || status > 0) {
            logError(@"chown did not exit cleanly: %d",status);
            [NSException raise:TCSExceptionCouldNotRepairPermissions
                        format:@"There was an error repairing directory permissions (Could not authorize chown:%d)",status];
        }
    }
    
}

@end
