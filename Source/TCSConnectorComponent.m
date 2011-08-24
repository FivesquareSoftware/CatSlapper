//
//  TCSConnectorComponent.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/4/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSConnectorComponent.h"
#import "TCSConstants.h"

@implementation TCSConnectorComponent


// OBJECT STUFF ============================================================= //

- (id) initWithParent:(TCSComponent *)aParent
                 name:(NSString *)aName {
    if(self = [super initWithParent:aParent name:aName]) {
        icon = [[NSImage imageNamed:@"connector"] retain];
    }
    return self;
}

- (void) updateWithComponent:(TCSComponent *)aComponent {
    [super updateWithComponent:aComponent];
    if([(NSObject *)aComponent isMemberOfClass:[TCSConnectorComponent class]]) {
        [self setPort:[(TCSConnectorComponent *)aComponent port]];
        [self setProtocol:[(TCSConnectorComponent *)aComponent protocol]];
        [self setScheme:[(TCSConnectorComponent *)aComponent scheme]];
        [self setIsSecure:[(TCSConnectorComponent *)aComponent isSecure]];
    }
}


- (BOOL) isEqual:(id)obj {
    if(![obj isMemberOfClass:[TCSConnectorComponent class]]) return NO;
    if(obj == nil) return NO;
    
    return ([[self port] isEqualToString:[(TCSConnectorComponent *)obj port]]);
}

- (NSString *) description {

    NSString *description = [super description];
    description = ([self name] != nil)
        ? [description stringByAppendingString:[self name]]
        : description;
    return description;
}


// COMPONENT PROTOCOL ======================================================= //

- (id) name {
    if(name == nil) {
        NSString *myName = (port != nil ? port: @"");
        myName = [myName stringByAppendingString:@" "];
        myName = [myName stringByAppendingString:(protocol != nil ? protocol : @"")];
        return myName;
    } else {
        return name;
    }
}

- (NSString *) statusText {
    NSString *myStatustext = @"";
    myStatustext = 
        [myStatustext stringByAppendingFormat:@"threads(current/active): %@/%@"
            ,(currentThreadCount != nil ? currentThreadCount : @"0")
            ,(currentThreadsBusy != nil ? currentThreadsBusy : @"0")];
    return myStatustext;
}

- (NSString *) componentInfo {
    /*
     Name: Catalina:type=Connector,port=8009
     port: 8009
     protocol: AJP/1.3
     scheme: http
     secure: false
     */
    NSString *infoString = @"";
    infoString = [infoString stringByAppendingFormat:
                    @"Name: %@",([self name] != nil ? [self name] : @"")];
    infoString = [infoString stringByAppendingFormat:
                    @"\nport: %@",(port != nil ? port : @"")];
    infoString = [infoString stringByAppendingFormat:
                    @"\nprotocol: %@",(protocol != nil ? protocol : @"")];
    infoString = [infoString stringByAppendingFormat:
                    @"\nscheme: %@",(scheme != nil ? scheme : @"")];
    infoString = [infoString stringByAppendingFormat:
                    @"\nsecure: %@",(isSecure != nil ? isSecure : @"")];
    return infoString;
}

- (NSString *)componentStatus {
    NSString *statusString = @"";

    //Max threads: 150 Min spare threads: 25 Max spare threads: 75 Current thread count: 25 Current thread busy: 2
    statusString = 
        [statusString stringByAppendingFormat:
            @"Max threads: %@"
            ,(maxThreads != nil ? maxThreads : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nMin spare threads: %@"
            ,(minSpareThreads != nil ? minSpareThreads : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nMax spare threads: %@"
            ,(maxSpareThreads != nil ? maxSpareThreads : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
             @"\nCurrent thread count: %@"
            ,(currentThreadCount != nil ? currentThreadCount : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nCurrent thread busy: %@"
            ,(currentThreadsBusy != nil ? currentThreadsBusy : @"")];

    //Max processing time: 1998 ms Processing time: 322 s Request count: 4121 Error count: 49 Bytes received: 0.00 MB Bytes sent: 109.86 MB
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nMax processing time: %@ ms"
            ,(maxTime != nil ? maxTime : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nProcessing time: %@ ms"
            , (processingTime != nil ? processingTime : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nRequest count: %@"
            , (requestCount != nil ? requestCount : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nError count: %@"
            , (errorCount != nil ? errorCount : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nBytes received: %@ MB"
            , (bytesReceived != nil ? bytesReceived : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nBytes sent: %@ MB"
            , (bytesSent != nil ? bytesSent : @"")];
    
    return statusString;
 }


// KVC ====================================================================== //

- (NSString *)port {
    return port;
}

- (void)setPort:(NSString *)newPort {
    [newPort retain];
    [port release];
    port = newPort;
}

- (NSString *)protocol {
    return protocol;
}

- (void)setProtocol:(NSString *)newProtocol {
    [newProtocol retain];
    [protocol release];
    protocol = newProtocol;
}

- (NSString *)scheme {
    return scheme;
}

- (void)setScheme:(NSString *)newScheme {
    [newScheme retain];
    [scheme release];
    scheme = newScheme;
}

- (NSString *)isSecure {
    return isSecure;
}

- (void)setIsSecure:(NSString *)newIsSecure {
    isSecure = newIsSecure;
}

- (NSString *)maxThreads {
    return maxThreads;
}

- (void)setMaxThreads:(NSString *)newMaxThreads {
    [newMaxThreads retain];
    [maxThreads release];
    maxThreads = newMaxThreads;
}

- (NSString *)minSpareThreads {
    return minSpareThreads;
}

- (void)setMinSpareThreads:(NSString *)newMinSpareThreads {
    [newMinSpareThreads retain];
    [minSpareThreads release];
    minSpareThreads = newMinSpareThreads;
}

- (NSString *)maxSpareThreads {
    return maxSpareThreads;
}

- (void)setMaxSpareThreads:(NSString *)newMaxSpareThreads {
    [newMaxSpareThreads retain];
    [maxSpareThreads release];
    maxSpareThreads = newMaxSpareThreads;
}

- (NSString *)currentThreadCount {
    return currentThreadCount;
}

- (void)setCurrentThreadCount:(NSString *)newCurrentThreadCount {
    [newCurrentThreadCount retain];
    [currentThreadCount release];
    currentThreadCount = newCurrentThreadCount;
}

- (NSString *)currentThreadsBusy {
    return currentThreadsBusy;
}

- (void)setCurrentThreadsBusy:(NSString *)newCurrentThreadsBusy {
    [newCurrentThreadsBusy retain];
    [currentThreadsBusy release];
    currentThreadsBusy = newCurrentThreadsBusy;
}

- (NSString *)maxTime {
    return maxTime;
}

- (void)setMaxTime:(NSString *)newMaxTime {
    [newMaxTime retain];
    [maxTime release];
    maxTime = newMaxTime;
}

- (NSString *)processingTime {
    return processingTime;
}

- (void)setProcessingTime:(NSString *)newProcessingTime {
    [newProcessingTime retain];
    [processingTime release];
    processingTime = newProcessingTime;
}

- (NSString *)requestCount {
    return requestCount;
}

- (void)setRequestCount:(NSString *)newRequestCount {
    [newRequestCount retain];
    [requestCount release];
    requestCount = newRequestCount;
}

- (NSString *)errorCount {
    return errorCount;
}

- (void)setErrorCount:(NSString *)newErrorCount {
    [newErrorCount retain];
    [errorCount release];
    errorCount = newErrorCount;
}

- (NSString *)bytesReceived {
    return bytesReceived;
}

- (void)setBytesReceived:(NSString *)newBytesReceived {
    [newBytesReceived retain];
    [bytesReceived release];
    bytesReceived = newBytesReceived;
}

- (NSString *)bytesSent {
    return bytesSent;
}

- (void)setBytesSent:(NSString *)newBytesSent {
    [newBytesSent retain];
    [bytesSent release];
    bytesSent = newBytesSent;
}

    
    
    
// NSCoding ================================================================= //

- (void) encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[self port] forKey:@"TCSPort"];
    [coder encodeObject:[self protocol] forKey:@"TCSProtocol"];
}

- (id) initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    port = [[coder decodeObjectForKey:@"TCSPort"] retain];
    protocol = [[coder decodeObjectForKey:@"TCSProtocol"] retain];
    return self;
}



@end
