//
//  TCSController+Scripting.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/2/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSController (Scripting)

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;
- (TCSKitty *) selectedKitty;
- (id) handleToggleSelectionScriptCommand:(NSScriptCommand *)command;
- (id) handleRestartSelectionScriptCommand:(NSScriptCommand *)command;

@end
