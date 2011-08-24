//
//  TCSStartupItemManager+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 5/27/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSStartupItemManager (Private)

- (void) _authorizedUpdateStartupItemForKitty:(TCSKitty *)tk;
- (void) _authorizedRemoveStartupItemForKitty:(TCSKitty *)tk;
- (NSMutableArray *) _startupItemArgsForKitty:(TCSKitty *)tk;
- (void) _readStartupItemManagerOut:(FILE *)managerPipe;
- (NSString *) _nameHashForKitty:(TCSKitty *)tk;

@end
