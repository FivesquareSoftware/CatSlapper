//
//  NSApplication+Scripting.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/2/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "NSApplication+Scripting.h"
#import "TCSConstants.h"
#import "TCSLogger.h"


@implementation NSApplication (Scripting)

- (id) handleToggleSelectionScriptCommand:(NSScriptCommand *)command {
    logDebug(@"handleToggleSelectionScriptCommand:%@",command);
    return [[self delegate] handleToggleSelectionScriptCommand:command];
}

- (id) handleRestartSelectionScriptCommand:(NSScriptCommand *)command {
    logDebug(@"handleRestartSelectionScriptCommand:%@",command);
    return [[self delegate] handleRestartSelectionScriptCommand:command];
}

@end
