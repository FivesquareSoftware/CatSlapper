//
//  TCSStartupItemManager.m
//  TomcatSlapper
//
//  Created by John Clayton on 5/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSStartupItemManager.h"
#import "TCSStartupItemManager+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import "TCSKitty.h"
#import "TCSAuthorizationHandler.h"

@implementation TCSStartupItemManager

// OBJECT STUFF ============================================================= //

- (void) awakeFromNib {
    enableStartupItemPath = 
    [[[NSBundle mainBundle] 
            pathForResource:@"EnableStartupItem" 
                     ofType:@"sh" 
                inDirectory:@"Scripts"] retain];
    disableStartupItemPath = 
        [[[NSBundle mainBundle] 
            pathForResource:@"DisableStartupItem" 
                     ofType:@"sh" 
                inDirectory:@"Scripts"] retain];
    authHandler = [TCSAuthorizationHandler sharedAuthHandler];
}

- (void) dealloc {
    [enableStartupItemPath release];
    [disableStartupItemPath release];
    [super dealloc];
}


// STARTUP ITEMS ============================================================ //

- (void) updateStartupItemForKitty:(TCSKitty *)tk {
    [NSThread detachNewThreadSelector:@selector(_authorizedUpdateStartupItemForKitty:) 
                             toTarget:self 
                           withObject:tk];
}

- (void) removeStartupItemForKitty:(TCSKitty *)tk {
    [NSThread detachNewThreadSelector:@selector(_authorizedRemoveStartupItemForKitty:) 
                             toTarget:self 
                           withObject:tk];    
}

@end


// PRIVATE ================================================================== //

@implementation TCSStartupItemManager (Private)

- (void) _authorizedUpdateStartupItemForKitty:(TCSKitty *)tk {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if([authHandler isAuthorized]) {
        OSStatus authStatus;
        
        FILE *managerPipe = NULL;
        NSMutableArray *argsArray = [self _startupItemArgsForKitty:tk];
        [argsArray addObject:@"-d"];
        [argsArray addObject:
            [[NSBundle mainBundle] pathForResource:@"Scripts" ofType:nil]];

        char *startupItemArgs[[argsArray count]+1];
        int i;
        for(i = 0; i < [argsArray count]; i++) {
            startupItemArgs[i] = (char *)[[argsArray objectAtIndex:i] cString];
            logTrace(@"adding arg: '%s'",startupItemArgs[i]);
        }
            startupItemArgs[[argsArray count]] = NULL;
        logDebug(@"running EnableStartupItem:%s withArgs:%@"
                 ,[enableStartupItemPath fileSystemRepresentation]
                 ,argsArray);
        
#ifndef ENABLE_STARTUP_ITEM_MD5_SUM
#warning "** WARNING ** ENABLE_STARTUP_ITEM_MD5_SUM NOT DEFINED!"
#endif
        const char *sum = ENABLE_STARTUP_ITEM_MD5_SUM;
        AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
        authStatus = runVerifiedTool 
            ([authHandler authorization], [enableStartupItemPath fileSystemRepresentation], authFlags
             , startupItemArgs, &managerPipe, sum); 
        
        if (authStatus != errAuthorizationSuccess) {
            logError(@"Could not authorize EnableStartupItem:%d",authStatus);
            // TODO alert user of problem
        }  else {
            [self _readStartupItemManagerOut:managerPipe];
            int pid;
            int status;
            pid = wait(&status);
            logDebug(@"status = %d",status);
            logDebug(@"clean exit: %d",WIFEXITED(status));
            if(pid == -1 || ! WIFEXITED(status) || status > 0) {
                logError(@"EnableStartupItem did not exit cleanly: %d",status);
                [tk setValue:[NSNumber numberWithBool:NO] forKey:@"enableStartupItem"];
                // TODO alert user of problem
            }
        }
            
    } 
    [pool release];
}

- (void) _authorizedRemoveStartupItemForKitty:(TCSKitty *)tk {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if([authHandler isAuthorized]) {
        OSStatus authStatus;
        
        FILE *managerPipe = NULL;        
        NSString *itemPath = 
            [@"/Library/StartupItems/" 
                stringByAppendingPathComponent:[self _nameHashForKitty:tk]];
        
        /* I have no idea why this doesn't work the FIRST time unless this
            array has more than one element */
        char *startupItemArgs[2] = {
            (char *)[itemPath cString]
            , NULL
        };
        
        logDebug(@"running DisableStartupItem:%s withArgs:%s"
                 ,[disableStartupItemPath fileSystemRepresentation]
                 ,startupItemArgs[0]);
        
#ifndef DISABLE_STARTUP_ITEM_MD5_SUM
#warning "** WARNING ** DISABLE_STARTUP_ITEM_MD5_SUM NOT DEFINED!"
#endif
        const char *sum = DISABLE_STARTUP_ITEM_MD5_SUM;
        AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
        
        authStatus = runVerifiedTool 
            ([authHandler authorization], [disableStartupItemPath fileSystemRepresentation], authFlags
             , startupItemArgs, &managerPipe, sum); 
        
        if (authStatus != errAuthorizationSuccess) {
            logError(@"Could not authorize DisableStartupItem:%d",authStatus);
            // TODO alert user of problem
        } else {
            [self _readStartupItemManagerOut:managerPipe];
            int pid;
            int status;
            logDebug(@"waiting");
            pid = wait(&status);
            logDebug(@"Exit status = %d",status);
            logDebug(@"Did exit clean: %d",WIFEXITED(status));
            if(pid == -1 || ! WIFEXITED(status) || status > 0) {
                logError(@"DisableStartupItem did not exit cleanly: %d",status);
                [tk setValue:[NSNumber numberWithBool:YES] forKey:@"enableStartupItem"];
                // TODO alert user of problem
            }
        }
    }
    [pool release];
}

- (NSMutableArray *) _startupItemArgsForKitty:(TCSKitty *)tk {
    NSMutableArray *argsArray = [[NSMutableArray alloc] init];
    
    NSString *name = [[tk name] lastPathComponent];
    
    [argsArray addObject:@"-r"];
    [argsArray addObject:name];

    [argsArray addObject:@"-n"];
    [argsArray addObject:[self _nameHashForKitty:tk]];
    
    [argsArray addObject:@"-j"];
    [argsArray addObject:[tk javaHome]];
    
    [argsArray addObject:@"-h"];
    [argsArray addObject:[tk catalinaHome]];

    [argsArray addObject:@"-p"];
    logDebug(@"catalinaPid = %@",[tk catalinaPid]);
    [argsArray addObject:[tk catalinaPid]];
    
    if([tk catalinaBase] != nil) {
        [argsArray addObject:@"-b"];
        [argsArray addObject:[tk catalinaBase]];
    }
    if([tk catalinaOpts] != nil) {
        [argsArray addObject:@"-t"];
        [argsArray addObject:[tk catalinaOpts]];
    }
        
    return [argsArray autorelease];
}

- (void) _readStartupItemManagerOut:(FILE *)managerPipe {
    @try {
        char myReadBuffer[128];        
        for(;;) {
            int bytesRead = read (fileno (managerPipe),
                                  myReadBuffer, sizeof (myReadBuffer));
            if (bytesRead < 1) break;
            NSString *oString = 
                [TCSIOUtils dataString:
                    [NSData dataWithBytes:myReadBuffer length:bytesRead]];
            logDebug(@"%@", oString);
        }
        fflush(managerPipe);
        fclose(managerPipe);
    }
    @catch (NSException * e) {
        logError(@"Error reading out from StartupItemManager (%@)",[e description]);
    }
}

- (NSString *) _nameHashForKitty:(TCSKitty *)tk {
    NSString *nameHash = nil;
    NSString *name = [[tk name] lastPathComponent];
    NSString *home = [tk catalinaHome];
    NSString *base = [tk catalinaBase];
    if(base != nil && ![base isEqualToString:home]) {
        nameHash = [NSString stringWithFormat:@"%@-%d%d"
            , name
            , [home hash]
            , [base hash]];
    } else {
        nameHash = [NSString stringWithFormat:@"%@-%d"
            , name
            , [home hash]];
    }
    return nameHash;
}


@end
