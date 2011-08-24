//
//  TCSCatSpanker.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/4/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//


#import "TCSCatSpanker.h"
#import "TCSCatSpanker+Private.h"
#import "TCSIOUtils.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSKitty.h"
#import "TCSProcess.h"
#import "TCSAuthorizationHandler.h"
#include <openssl/md5.h>

@implementation TCSCatSpanker

static TCSCatSpanker *spanker;

// OBJECT STUFF ============================================================= //

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super init]) {
        
    }
    return self;
}


// SINGLETON SPANKER ======================================================== //

+ (id) sharedSpanker {
    if(spanker == nil) {
        spanker = [[TCSCatSpanker alloc] _init];
    }
    return spanker;
}


// TOMCAT METHODS =========================================================== //


+ (NSDictionary *) toggleTomcat:(TCSKitty *)tk {
    //logDebug(@"toggleTomcat:%@",tk);
    NSString *startCommand = [tk valueForKey:@"startCommand"];
    logDebug(@"startCommand = %@",startCommand);
    //NSArray *commandsArray = [startCommand componentsSeparatedByString:@" "];
    NSArray *commands = ([tk isRunning] 
                         ? [NSArray arrayWithObject:@"stop"]
                         : [NSArray arrayWithObject:startCommand]);
    logDebug(@"commands = %@",commands);
    logDebug(@"tk.runPrivileged = %d",[tk runPrivileged]);
    return [tk runPrivileged]
        ? [[TCSCatSpanker sharedSpanker] _authorizedRun:commands onKitty:tk]
        : [[TCSCatSpanker sharedSpanker] _run:commands onKitty:tk];
}

+ (NSDictionary *) restartTomcat:(TCSKitty *)tk {
    NSString *startCommand = [tk valueForKey:@"startCommand"];
    logDebug(@"startCommand = %@",startCommand);
    NSArray *commands = [NSArray arrayWithObjects:@"stop",startCommand,nil];
    return [tk runPrivileged]
            ? [[TCSCatSpanker sharedSpanker] _authorizedRun:commands onKitty:tk]
            : [[TCSCatSpanker sharedSpanker]  _run:commands onKitty:tk];
}


// KVC ====================================================================== //

- (NSString *)stdErrFilePath {
    return stdErrFilePath;
}

- (void)setStdErrFilePath:(NSString *)newStdErrFilePath {
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


@end



// PRIVATE ================================================================== //

@implementation TCSCatSpanker (Private)

- (NSDictionary *) _run:(NSArray *)commands onKitty:(TCSKitty *)tk {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    BOOL wasRunning = [tk isRunning];
    NSString *runnerPath = 
        [[[NSBundle mainBundle] 
            pathForResource:@"TomcatSlapper" 
                     ofType:@"sh" 
                inDirectory:@"Scripts"] retain];
        
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    NSFileHandle *stdoutHandle = [outPipe fileHandleForReading];
    NSMutableData *inData = [NSMutableData data];
    [self _generateStdErrHandle];    
    

    NSMutableArray *runnerArgs = [self _runnerArgsForKitty:tk];
    [runnerArgs addObjectsFromArray:commands];
    // slapper expects a null element at the end
    // since this is how security services sends the args array
    //[runnerArgs addObject:@""];
    
    [task setLaunchPath:runnerPath];
    [task setArguments:runnerArgs];
    
    [task setStandardOutput:outPipe];
    [task setStandardError:outPipe];

    [task launch];
    
    [TCSIOUtils readIntoData:inData fromHandle:stdoutHandle];
    NSString *runnerOut = [TCSIOUtils dataString:inData];
    logDebug(@"runnerOut = %@",runnerOut);
    if(runnerOut != nil) {
        [output setObject:runnerOut forKey:[NSNumber numberWithInt:TCS_STDOUT]];
    }
    [task waitUntilExit];
    int status = [task terminationStatus];
    if(status==0) {
        if(wasRunning) {
            [tk setProcess:nil];
        } else {
           [self _setProcessFromPidfileForKitty:tk];   
        }
    }
    [task release];
    [self _readErrFileToOutput:output];
    return output;
}

- (NSDictionary *) _authorizedRun:(NSArray *)commands onKitty:(TCSKitty *)tk {
    logDebug(@"_authorizedRun:%@",commands);
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    TCSAuthorizationHandler *authHandler = [TCSAuthorizationHandler sharedAuthHandler];
    if([authHandler isAuthorized]) {
        BOOL wasRunning = [tk isRunning];
        OSStatus authStatus;

        // IF YOU EXPLICITLY USE BASH, EUID WON'T BE SET!!! USE SH!
        // TODO: get rid of shell scripts altogether and use launchd for everything
        NSString *runnerPath = 
            [[[NSBundle mainBundle] 
            pathForResource:@"TomcatSlapper" 
                     ofType:@"sh" 
                inDirectory:@"Scripts"] retain];
        
        [self _generateStdErrHandle];
        FILE *runnerPipe = NULL;
        
        NSArray *argsArray = [self _runnerArgsForKitty:tk];
        int argsLength = [argsArray count]+[commands count]+1;
        logDebug(@"runnerArgs.length = %d",argsLength);
        char *runnerArgs[argsLength];
        
        unsigned int i, count = [argsArray count];
        for(i = 0; i < count; i++) {
            logDebug(@"runnerArgs[%d] = %@",i,[argsArray objectAtIndex:i]);
            runnerArgs[i] = (char *)[[argsArray objectAtIndex:i] cString];
        }
        
        unsigned int j;
        count = [commands count];
        for (j = 0; j < count; j++) {
            NSString *command = [commands objectAtIndex:j];
            logDebug(@"runnerArgs[%d] = %@",[argsArray count]+j,command);
            runnerArgs[[argsArray count]+j] = (char *)[command cString];
        }
        int nullIndex = [argsArray count]+j;
        logDebug(@"nullIndex = %d",nullIndex);
        runnerArgs[nullIndex] = NULL;
        
        logDebug(@"running runner:%s withArgs:%@ commands:%@", [runnerPath fileSystemRepresentation], argsArray, commands);
        
        unsigned int k;
        count = [argsArray count]+[commands count];
        for (k = 0; k < count; k++) {
            logDebug(@"runnerArgs[%d] = %s",k,runnerArgs[k]);
        }
        
#ifndef SLAPPER_MD5_SUM
#warning "** WARNING ** SLAPPER_MD5_SUM NOT DEFINED!"
#endif
        const char *sum = SLAPPER_MD5_SUM;
        AuthorizationFlags authFlags = kAuthorizationFlagDefaults; 
        authStatus = runVerifiedTool(
             [authHandler authorization]
             , [runnerPath fileSystemRepresentation], authFlags
             , runnerArgs, &runnerPipe, sum); 
        
        if (authStatus != errAuthorizationSuccess) {
            logError(@"Could not authorize runner:%d",authStatus);
            [authHandler alertUser:authStatus];
        }  else {
            // set stdout
            NSData *outData = [self _readRunnerOut:runnerPipe];
            NSString *runnerOut = [TCSIOUtils dataString:outData];
            logDebug(@"runnerOut = %@",runnerOut);
            if(runnerOut != nil) {
                [output setObject:runnerOut
                           forKey:[NSNumber numberWithInt:TCS_STDOUT]];
            }
            
            int pid;
            int status;
            pid = wait(&status);
            logDebug(@"status = %d",status);
            logDebug(@"clean exit: %d",WIFEXITED(status));
            if(pid == -1 || ! WIFEXITED(status) || status > 0) {
                logError(@"Runner did not exit cleanly: %d",status);
                //TODO tell user?
            } else {
                if(wasRunning) {
                    [tk setProcess:nil];
                } else {
                    [self _setProcessFromPidfileForKitty:tk];
                }
            }
            [self _readErrFileToOutput:output];
        }
    }
    return output;
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

- (NSMutableArray *) _runnerArgsForKitty:(TCSKitty *)tk {
    NSMutableArray *argsArray = [NSMutableArray array];

    [argsArray addObject:@"-e"];
    [argsArray addObject:stdErrFilePath];
    
    [argsArray addObject:@"-j"];
    [argsArray addObject:[tk javaHome]];

    [argsArray addObject:@"-h"];
    [argsArray addObject:[tk catalinaHome]];
    
    if([tk catalinaBase] != nil) {
        [argsArray addObject:@"-b"];
        [argsArray addObject:[tk catalinaBase]];
    }

    [argsArray addObject:@"-p"];
    [argsArray addObject:[tk catalinaPid]];

    if([tk catalinaOpts] != nil) {
        [argsArray addObject:@"-t"];
        [argsArray addObject:[tk catalinaOpts]];
    }

    if([tk jpdaTransport] != nil) {
        [argsArray addObject:@"-j"];
        [argsArray addObject:[tk jpdaTransport]];
    }

    if([tk jpdaAddress] != nil) {
        [argsArray addObject:@"-s"];
        [argsArray addObject:[tk jpdaAddress]];
    }
    
    return argsArray;
}

- (NSData *) _readRunnerOut:(FILE *)runnerPipe {
    NSMutableData *outData = [NSMutableData data];
    char myReadBuffer[128]; 
    @try {
        for(;;) {
            int bytesRead = read (fileno (runnerPipe),
                                  myReadBuffer, sizeof (myReadBuffer));
            if (bytesRead < 1) break;
            [outData appendBytes:myReadBuffer length:bytesRead];
            logTrace(@"runner.out = %@",[TCSIOUtils dataString:outData]);
        }
    } @catch(NSException *e) {
        logError(@"There was a problem reading runner out: %@",[e description]);
    } @finally {
        fflush(runnerPipe);
        fclose(runnerPipe);
    }
    return outData;
}

- (void) _setProcessFromPidfileForKitty:(TCSKitty *)tk {
    NSFileHandle *pidFH = [NSFileHandle fileHandleForReadingAtPath:[tk catalinaPid]];
    NSData *pidData = [pidFH readDataToEndOfFile];
    NSString *pidString = [[NSString alloc] initWithData:pidData
                                                encoding:NSUTF8StringEncoding];
    [pidFH closeFile];
    int pid = [pidString intValue];
    TCSProcess *proc = [TCSProcess processForProcessIdentifier:pid];
    [tk setProcess:proc];  
    [pidString release];
}

- (void) _readErrFileToOutput:(NSMutableDictionary *)output {
    NSData *errData = [taskStdErrHandle readDataToEndOfFile];
    NSString *runnerErr = [TCSIOUtils dataString:errData];
    if(runnerErr != nil) {
        logDebug(@"runnerErr = %@",runnerErr);
        [output setObject:runnerErr
                   forKey:[NSNumber numberWithInt:TCS_STDERR]];
    }
    [taskStdErrHandle closeFile];
    [[NSFileManager defaultManager] removeFileAtPath:stdErrFilePath handler:NULL];
}


@end
