//
//  NSArrayController+TCSUtils.m
//  TomcatSlapper
//
//  Created by John Clayton on 8/22/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "NSArrayController+TCSUtils.h"
#import "TCSLogger.h"


@implementation NSArrayController (TCSUtils)

/*
 * What you may actually get is _NSStateMarker which has no boolValue: selector
 */
- (BOOL) safeBoolValueForKey:(NSString *)key {
    id value = [self valueForKey:key];
    logTrace(@"value = %@",value);
    BOOL boolValue = [value isEqual:[NSNumber numberWithInt:1]] ? YES : NO;
    logTrace(@"boolValue = %d",boolValue);
    return boolValue;    
}

/*
 * What you may actually get is _NSStateMarker which has no boolValue: selector
 */
- (BOOL) safeBoolValueForKeyPath:(NSString *)keyPath {
    id value = [self valueForKeyPath:keyPath];
    logTrace(@"value = %@",value);
    BOOL boolValue = [value isEqual:[NSNumber numberWithInt:1]] ? YES : NO;
    logTrace(@"boolValue = %d",boolValue);
    return boolValue;    
}

@end
