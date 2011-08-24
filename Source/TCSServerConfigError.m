//
//  TCSServerConfigError.m
//  TomcatSlapper
//
//  Created by John Clayton on 12/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSServerConfigError.h"


@implementation TCSServerConfigError


+ (id) errorForKey:(NSString *)errorKey value:(id) badValue {
    NSString *mySummary = NSLocalizedString(
                                  [errorKey stringByAppendingString:@".summary"]
                                  ,nil);
    mySummary = [NSString stringWithFormat:mySummary,badValue];
    NSString *myExplanation = NSLocalizedString(
                                  [errorKey stringByAppendingString:@".explanation"]
                                  ,nil);
    myExplanation = [NSString stringWithFormat:myExplanation,badValue];

    TCSServerConfigError *error = [[[TCSServerConfigError alloc] init] autorelease];
    [error setSummary:mySummary];
    [error setExplanation:myExplanation];
    return error;
}

- (NSString *)summary {
    return summary;
}

- (void)setSummary:(NSString *)newSummary {
    [newSummary retain];
    [summary release];
    summary = newSummary;
}

- (NSString *)explanation {
    return explanation;
}

- (void)setExplanation:(NSString *)newExplanation {
    [newExplanation retain];
    [explanation release];
    explanation = newExplanation;
}

@end
