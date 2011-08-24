//
//  TCSConsoleView.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/1/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCSLayoutManager;

@protocol TCSConsoleClientMethods 

- (void) addServer:(id)newServer forFilename:(in bycopy NSString *)filename;
- (oneway void) appendData:(in bycopy NSData *)data 
                       forFile:(in bycopy NSString *)filename
                      type:(in bycopy int)type;
- (oneway void) serverLaunched:(id)newServer;
- (void) didTerminateFor:(id)server withStatus:(in bycopy int)status;

@end

@interface TCSConsoleView : NSTextView <TCSConsoleClientMethods> {
    @private
    NSMutableDictionary *consoleServers;
    NSMutableArray *pendingServers;
    NSMutableArray *runningServers;
    NSMutableArray *stoppedServers;
    NSString *activeFile;
    NSMutableDictionary *textStorageByFile;
}


- (void) createConsoleServer:(NSString *)fileName;

- (NSTextStorage *) createTextStorage;
- (void) addTextStorage:(NSTextStorage *)container 
         forFixedFilename:(NSString *)fixedFilename ;
- (NSTextStorage *) textStorageForKey:(NSString *)filename;
- (TCSLayoutManager *) layoutManagerForKey:(NSString *)filename;

- (id) serverForKey:(NSString *)filename;
- (NSDictionary *) consoleServersCopy;
- (NSArray *) filenames;
- (void) startServer:(NSString *)filename;
- (void) destroyServer:(NSString *)filename;
- (void) terminateServer:(NSString *)filename;
- (void) terminateServer:(NSString *)filename forced:(BOOL)forced;
- (void) terminateServers:(NSArray *)filenames;
- (void) terminateAllServers:(BOOL)forced;
- (NSString *) activeFile;
- (void) setActiveFile:(NSString *)newActiveFile;
- (void) activateTextStorageFor:(NSString *)filename;
- (void) appendString:(NSString *)someText forFile:(NSString *)filename;
- (void) appendString:(NSString *)someText  forFile:(NSString *)filename type:(int)type;
- (void) clear;
- (int) runningServerCount;
- (int) stoppedServerCount;
- (NSString *) resolveFileName:(NSString *)filename;
- (void) resetFontFromDefaults:(NSTextStorage *)storage;
- (void) scrollToEnd:(NSTextStorage *)storage;

- (void) registerObservations;
- (void) removeObservations;

@end
