//
//  NSArrayController+TCSUtils.h
//  TomcatSlapper
//
//  Created by John Clayton on 8/22/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArrayController (TCSUtils) 

- (BOOL) safeBoolValueForKey:(NSString *)key;
- (BOOL) safeBoolValueForKeyPath:(NSString *)keyPath;

@end
