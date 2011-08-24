//
//  TCSProcess.h
//  TomcatSlapper
//
//  Created by John Clayton on 5/20/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSProcess : NSObject {
    int processIdentifier;
    NSString *ucomm;
    NSDate *startTime;
    NSString *fullCommand;
    NSMutableArray *arguments;
    NSMutableDictionary *environment;
}

+ (NSArray *) processesForCommand:(NSString *)aCommand;
+ (TCSProcess *) processForProcessIdentifier:(int)aPid;

- (id) initWithProcessIdentifier:(int)aPid;

- (NSString *) runningTime;

- (int)processIdentifier;
- (void)setProcessIdentifier:(int)newPid;
- (NSString *)ucomm;
- (void)setUcomm:(NSString *)newUcomm;
- (NSDate *)startTime;
- (void)setStartTime:(NSDate *)newStartTime;
- (NSString *)fullCommand;
- (void)setFullCommand:(NSString *)newFullCommand;
- (NSMutableArray *)arguments;
- (void)setArguments:(NSMutableArray *)newArguments;
- (NSMutableDictionary *)environment;
- (void)setEnvironment:(NSMutableDictionary *)newEnvironment;

@end
