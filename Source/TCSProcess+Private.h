//
//  TCSProcess+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 5/25/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSProcess (Private)

+ (NSString *) _psWithArguments:(NSArray *)arguments;
+ (NSArray *) _processes:(NSString *)psout;
+ (void) _parse:(NSString *)commandAndArgsString intoProcess:(TCSProcess *)process;

@end
