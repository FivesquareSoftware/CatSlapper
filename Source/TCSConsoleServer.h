//
//  TCSConsoleServer.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/1/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TCSConsoleServerMethods

- (out bycopy NSString *) filename;
- (oneway void) tail;
- (oneway void) terminate:(BOOL)forced;

@end


@interface TCSConsoleServer : NSObject {
    id client;
    NSString *filename;
    NSMutableData *tailData;
    NSArray *modes;
    NSFileHandle *readHandle;
    BOOL terminate;
}

- (id) initWithClient:(id)newClient filename:(NSString *)aFilename;
+ (void) connectForFileWithPorts:(NSDictionary *)args;

- (NSFileHandle *)readHandle;
- (void)setReadHandle:(NSFileHandle *)newReadHandle;

- (void) _waitOnFile;
- (void) _tailFile;

@end
