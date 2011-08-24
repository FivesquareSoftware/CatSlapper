//
//  TCSServerConfigError.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSServerConfigError : NSObject {
    NSString *summary;
    NSString *explanation;
}

+ (id) errorForKey:(NSString *)errorKey value:(id)value;

- (NSString *)summary;
- (void)setSummary:(NSString *)newSummary;
- (NSString *)explanation;
- (void)setExplanation:(NSString *)newExplanation;

@end
