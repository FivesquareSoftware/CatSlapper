//
//  TCSConsoleServer.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/1/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSConsoleServer.h"
#import "TCSConsoleView.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"


@implementation TCSConsoleServer

- (id) initWithClient:(id)newClient filename:(NSString *)aFilename {
    logDebug(@"initWithClient:%@ filename:%@",newClient,filename);
    if(self = [super init]) {
        client = newClient;
        filename = [aFilename retain];
        //BACTRACK removed extra retains
        tailData = [[NSMutableData alloc] init];
        modes = [[NSArray arrayWithObjects:
            NSDefaultRunLoopMode
            ,NSConnectionReplyMode,nil] retain];
        terminate = NO;
        
        [[NSNotificationCenter defaultCenter] 
            addObserver:self 
               selector:@selector(applicationDidResign:) 
                   name:@"NSApplicationDidResignActiveNotification" 
                 object:nil];
        [[NSNotificationCenter defaultCenter] 
            addObserver:self 
               selector:@selector(applicationDidBecomeActive:) 
                   name:@"NSApplicationWillBecomeActiveNotification" 
                 object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [readHandle release];
    [filename release];
    [tailData release];
    [modes release];
    [super dealloc];
}

+ (void) connectForFileWithPorts:(NSDictionary *)args {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    logDebug(@"connectForFileWithPorts:%@",args);
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    NSString *myFilename = [args objectForKey:TCSConsoleServerArgFilename];
    
    NSConnection *serverConnection = 
        [NSConnection 
            connectionWithReceivePort:[args objectForKey:TCSConsoleServerArgSendPort] 
                             sendPort:[args objectForKey:TCSConsoleServerArgRcvPort]
        ];
    logDebug(@"serverConnection = %@",serverConnection);
    [serverConnection enableMultipleThreads];
    logDebug(@"serverConnection.enableMultipleThreads");
    id proxy = [serverConnection rootProxy];
    logDebug(@"proxy = %@",proxy);
    TCSConsoleServer *server = [[self alloc] initWithClient:proxy filename:myFilename];
    logDebug(@"server = %@",server);
    [proxy setProtocolForProxy:@protocol(TCSConsoleClientMethods)];
    [proxy addServer:server forFilename:myFilename];
    [server release];
        
    logTrace(@"NSRunLoop.currentRunLoop.currentMode: %@",[runLoop currentMode]);
    [runLoop run];
    [pool release];
}

- (void) readData {
    if(terminate) {
        [readHandle closeFile];
        [self setReadHandle:nil];
        return;
    }
    NSData *tmpData = [readHandle readDataOfLength:LOG_FILE_TAIL_BUFFER];
    if([tmpData length] > 0) {
        [tailData  appendData:tmpData]; 
        NSData *outData = [NSData dataWithData:tailData];
        [tailData setLength:0];
        logTrace(@"outData = %@",outData);
        [client appendData:outData forFile:filename type:TCS_SERVER_LOG];
        [self readData];
    } else{
        [NSTimer scheduledTimerWithTimeInterval:LOG_FILE_TAIL_INTERVAL
                 target:self 
               selector:@selector(readData) 
               userInfo:nil 
                repeats:NO]; 
    }
}

- (void) applicationDidResign:(NSNotification *)notification {
    logTrace(@"NSRunLoop.currentRunLoop.currentMode: %@",[[NSRunLoop currentRunLoop] currentMode]);
}

- (void) applicationDidBecomeActive:(NSNotification *)notification {
    logTrace(@"NSRunLoop.currentRunLoop.currentMode: %@",[[NSRunLoop currentRunLoop] currentMode]);
}


// KVC ====================================================================== //

- (NSFileHandle *)readHandle {
    return readHandle;
}

- (void)setReadHandle:(NSFileHandle *)newReadHandle {
    [newReadHandle retain];
    [readHandle release];
    readHandle = newReadHandle;
}



// SERVER PROTOCOL METHODS ================================================== //


- (out bycopy NSString *) filename {
    return filename;
}

- (oneway void) tail {
    logDebug(@"tail: %@",filename);
    terminate = NO; //in case we are being restarted
    //let the client know we are doing it
    [client serverLaunched:self];

    NSFileHandle *myHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
    if(myHandle == nil) {
        logWarn(@"Could not create filehandle for file: %@, waiting",filename);
        [self _waitOnFile];
    } else {
        [self setReadHandle:myHandle];
        [self _tailFile];
    }
}

- (void) _waitOnFile {
    if(terminate) return; //we're done
    NSFileHandle *myHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
    if(myHandle == nil) {
         [NSTimer scheduledTimerWithTimeInterval:LOG_FILE_TAIL_INTERVAL
                                          target:self 
                                        selector:@selector(_waitOnFile) 
                                        userInfo:nil 
                                         repeats:NO];    
     } else {
         [self setReadHandle:myHandle];
         [self _tailFile];
     }
}

- (void) _tailFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *atts = [fm fileAttributesAtPath:filename traverseLink:NO];
    logTrace(@"atts: %@",atts);
    NSNumber *fSize = [atts objectForKey:NSFileSize];
    logTrace(@"fSize.longLongValue: %qu",[fSize longLongValue]);
    if([fSize longLongValue] >= LOG_FILE_TAIL_OFFSET) {
        unsigned long long offset = [fSize longLongValue] - LOG_FILE_TAIL_OFFSET;
        logTrace(@"offset: %qu",offset);
        logTrace(@"seeking to: %qu",offset);
        [readHandle seekToFileOffset:offset];
        logTrace(@"offsetInFile: %qu",[readHandle offsetInFile]);
    }        
    [self readData];
}

- (oneway void) terminate:(BOOL)forced {
    logDebug( @"terminate");
    terminate = YES;
    if(!forced) {
        [client didTerminateFor:self withStatus:0];
    }
}

@end



