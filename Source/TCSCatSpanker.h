//
//  TCSCatSpanker.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/4/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSCatSpanker : NSObject {
    NSString *stdErrFilePath;
    NSFileHandle *taskStdErrHandle;

}

+ (id) sharedSpanker;
+ (NSDictionary *) toggleTomcat:(TCSKitty *)tk;
+ (NSDictionary *) restartTomcat:(TCSKitty *)tk;

- (NSString *)stdErrFilePath;
- (void)setStdErrFilePath:(NSString *)newStdErrFilePath;
- (NSFileHandle *)taskStdErrHandle;
- (void)setTaskStdErrHandle:(NSFileHandle *)newTaskStdErrHandle;


@end
