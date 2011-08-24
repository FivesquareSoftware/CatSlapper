//
//  TCSPrefController.h
//  TomcatSlapper
//
//  Created by John Clayton on 10/24/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSPrefController : NSWindowController {
    BOOL useShellEnv;
    NSMutableDictionary *defaultVariables;
    NSColor *backgroundColor;
    NSColor *stdoutColor;
    NSColor *stderrColor;
    NSColor *serverLogColor;
    NSColor *hostLogColor;
    NSFont *consoleFont;
    BOOL manualComponentUpdates;
    NSNumber *componentUpdatesEvery;
    BOOL shouldMeow;
    BOOL canUseAccessControlLists;
    BOOL canRunTomcatsPrivileged;
    BOOL canRepairPermissions;

    IBOutlet NSObjectController *defCon;
    IBOutlet NSWindow *entryWin;
    IBOutlet NSTextField *catalinaOptsField;
    IBOutlet NSTextField *entryField;
}

+ (TCSPrefController *) sharedPrefController;

- (IBAction) loadUserShellEnvironment:(id)sender;
- (IBAction) browse:(id)sender;
- (IBAction) editOpts:(id)sender;
- (IBAction) didEndEditOpts:(id)sender;
- (IBAction) selectFont:(id)sender;

- (NSObjectController *)defCon;
- (void)setDefCon:(NSObjectController *)newDefCon;
- (BOOL)useShellEnv;
- (void)setUseShellEnv:(BOOL)newUseShellEnv;
- (NSMutableDictionary *)defaultVariables;
- (void)setDefaultVariables:(NSMutableDictionary *)newDefaultVariables;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;
- (NSColor *)stdoutColor;
- (void)setStdoutColor:(NSColor *)newStdoutColor;
- (NSColor *)stderrColor;
- (void)setStderrColor:(NSColor *)newStderrColor;
- (NSColor *)serverLogColor;
- (void)setServerLogColor:(NSColor *)newServerLogColor;
- (NSColor *)hostLogColor;
- (void)setHostLogColor:(NSColor *)newHostLogColor;
- (NSFont *)consoleFont;
- (void)setConsoleFont:(NSFont *)newConsoleFont;
- (BOOL)manualComponentUpdates;
- (void)setManualComponentUpdates:(BOOL)newManualComponentUpdates;
- (NSNumber *)componentUpdatesEvery;
- (void)setComponentUpdatesEvery:(NSNumber *)newComponentUpdatesEvery;
- (BOOL)shouldMeow;
- (void)setShouldMeow:(BOOL)newShouldMeow;
- (BOOL)canUseAccessControlLists;
- (void)setCanUseAccessControlLists:(BOOL)newCanUseAccessControlLists;
- (BOOL)canRunTomcatsPrivileged;
- (void)setCanRunTomcatsPrivileged:(BOOL)newCanRunTomcatsPrivileged;
- (BOOL)canRepairPermissions;
- (void)setCanRepairPermissions:(BOOL)newCanRepairPermissions;

- (NSString *)javaHome;
- (void)setJavaHome:(NSString *)newJavaHome;
- (NSString *)catalinaHome;
- (void)setCatalinaHome:(NSString *)newCatalinaHome;
- (NSString *)catalinaBase;
- (void)setCatalinaBase:(NSString *)newCatalinaBase;
- (NSString *)catalinaOpts;
- (void)setCatalinaOpts:(NSString *)newCatalinaOpts;
- (NSString *)jpdaTransport;
- (void)setJpdaTransport:(NSString *)newJpdaTransport;
- (NSString *)jpdaAddress;
- (void)setJpdaAddress:(NSString *)newJpdaAddress;
- (NSColor *) colorForOutputType:(int)type;
- (NSColor *) colorForAttribute:(NSString *) attribute;
- (NSString *) attributeForOutputType:(int)type;

- (void) _saveDefaults;

@end
