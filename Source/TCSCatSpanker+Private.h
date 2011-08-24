//
//  TCSCatSpanker+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 6/29/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSCatSpanker (Private)

- (NSDictionary *) _run:(NSArray *)commands onKitty:(TCSKitty *)tk;
- (NSDictionary *) _authorizedRun:(NSArray *)commands onKitty:(TCSKitty *)tk;
- (void) _generateStdErrHandle;
- (NSMutableArray *) _runnerArgsForKitty:(TCSKitty *)tk;
- (NSData *) _readRunnerOut:(FILE *)runnerPipe;
- (void) _setProcessFromPidfileForKitty:(TCSKitty *)tk;
- (void) _readErrFileToOutput:(NSMutableDictionary *)output;

@end
