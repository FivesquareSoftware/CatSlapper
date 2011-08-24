//
//  TCSConnectorComponent.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/4/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSComponent.h"

@interface TCSConnectorComponent : TCSComponent {
    NSString *port;
    NSString *protocol;    
    NSString *scheme;
    NSString *isSecure;
    
    NSString *maxThreads;
    NSString *minSpareThreads;
    NSString *maxSpareThreads;
    NSString *currentThreadCount;
    NSString *currentThreadsBusy;

    NSString *maxTime;
    NSString *processingTime;
    NSString *requestCount;
    NSString *errorCount;
    NSString *bytesReceived;
    NSString *bytesSent;
        
}


- (NSString *)port;
- (void)setPort:(NSString *)newPort;
- (NSString *)protocol;
- (void)setProtocol:(NSString *)newProtocol;
- (NSString *)scheme;
- (void)setScheme:(NSString *)newScheme;
- (NSString *)isSecure;
- (void)setIsSecure:(NSString *)newIsSecure;

- (NSString *)maxThreads;
- (void)setMaxThreads:(NSString *)newMaxThreads;
- (NSString *)minSpareThreads;
- (void)setMinSpareThreads:(NSString *)newMinSpareThreads;
- (NSString *)maxSpareThreads;
- (void)setMaxSpareThreads:(NSString *)newMaxSpareThreads;
- (NSString *)currentThreadCount;
- (void)setCurrentThreadCount:(NSString *)newCurrentThreadCount;
- (NSString *)currentThreadsBusy;
- (void)setCurrentThreadsBusy:(NSString *)newCurrentThreadsBusy;
- (NSString *)maxTime;
- (void)setMaxTime:(NSString *)newMaxTime;
- (NSString *)processingTime;
- (void)setProcessingTime:(NSString *)newProcessingTime;
- (NSString *)requestCount;
- (void)setRequestCount:(NSString *)newRequestCount;
- (NSString *)errorCount;
- (void)setErrorCount:(NSString *)newErrorCount;
- (NSString *)bytesReceived;
- (void)setBytesReceived:(NSString *)newBytesReceived;
- (NSString *)bytesSent;
- (void)setBytesSent:(NSString *)newBytesSent;


@end
