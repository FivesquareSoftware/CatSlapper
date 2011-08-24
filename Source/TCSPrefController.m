//
//  TCSPrefController.m
//  TomcatSlapper
//
//  Created by John Clayton on 10/24/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSPrefController.h"
#import "TCSPrefController+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSUserShell.h"



@implementation TCSPrefController

static TCSPrefController *controller;

// OBJECT STUFF ============================================================= //


+ (void) initialize {
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"javaHome"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"catalinaHome"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"catalinaBase"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"catalinaOpts"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"jpdaTransport"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"jpdaAddress"];
    [self setKeys:[NSArray arrayWithObject:@"defaultVariables"] 
            triggerChangeNotificationsForDependentKey:@"logfile"];

    [self setKeys:[NSArray arrayWithObject:@"consoleFont"] 
            triggerChangeNotificationsForDependentKey:@"consoleFontName"];
}

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super initWithWindowNibName:@"Preferences"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *defsAsData = [defaults dataForKey:TCSUserDefaultsDefaultValues];  
        if(defsAsData != nil) {
            defaultVariables = [[NSKeyedUnarchiver unarchiveObjectWithData:defsAsData] mutableCopy];
        } else {
            defaultVariables = [[NSMutableArray alloc] init];
        }
        //[defaultVariables retain];
        
        useShellEnv = [defaults boolForKey:TCSUserDefaultsUseShellEnv];

        NSData *colorData = [defaults dataForKey:TCSUserDefaultsTextColorBackground];
        backgroundColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];

        colorData = [defaults dataForKey:TCSUserDefaultsTextColorStdout];
        stdoutColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];
        
        colorData = [defaults dataForKey:TCSUserDefaultsTextColorStderr];
        stderrColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];
        
        colorData = [defaults dataForKey:TCSUserDefaultsTextColorServerLog];
        serverLogColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];
        
        colorData = [defaults dataForKey:TCSUserDefaultsTextColorHostLog];
        hostLogColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];
        
        NSData *fontData = [defaults dataForKey:TCSUserDefaultsConsoleFont];
        consoleFont = [[NSKeyedUnarchiver unarchiveObjectWithData:fontData] retain];
        
        manualComponentUpdates = [defaults boolForKey:TCSUserDefaultsManualComponentUpdates];
        componentUpdatesEvery = [[defaults objectForKey:TCSUserDefaultsComponentUpdatesEvery] retain];

        shouldMeow = [defaults boolForKey:TCSUserDefaultsShouldMeow];

        canUseAccessControlLists = [defaults boolForKey:TCSUserDefaultsCanSetACLs];
        canRunTomcatsPrivileged = [defaults boolForKey:TCSUserDefaultsCanRunTomcatsPrivileged];
        canRepairPermissions = [defaults boolForKey:TCSUserDefaultsCanRepairPermissions];
}
    return self;
}

- (void) dealloc {
    [defaultVariables release];
    [stdoutColor release];
    [stderrColor release];
    [serverLogColor release];
    [hostLogColor release];
    [consoleFont release];
    [componentUpdatesEvery release];
    [super dealloc];
}

// SINGLETON PREF CONTROLLER ================================================ //


+ (TCSPrefController *) sharedPrefController {
    if(controller == nil) {
        controller = [[TCSPrefController alloc] _init];
        if([controller useShellEnv]) [controller loadUserShellEnvironment:self];
        //logDebug(@"defaultVariables = %@",[controller defaultVariables]);
        [controller window]; //loads nib
    }
    return controller;
}


// IBACTIONS ================================================================ //

- (IBAction) loadUserShellEnvironment:(id)sender {
    [self setDefaultVariables:[TCSUserShell currentEnvironmentFromUserShell]];
}


- (IBAction) browse:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setAllowsMultipleSelection:NO];
    //it's bizarre that I should have to retain this, the panel should do it
    NSNumber *picking = [[NSNumber numberWithInt:[sender tag]] retain];
    [op  beginSheetForDirectory:nil
                           file:nil
                          types:nil
                 modalForWindow:[sender window]
                  modalDelegate:self
                 didEndSelector:@selector(browseDidEnd:returnCode:contextInfo:)
                    contextInfo:picking
        ];
}

- (void) browseDidEnd:(NSOpenPanel *)sheet 
           returnCode:(int)returnCode 
          contextInfo:(void  *)contextInfo {
    //user cancelled
    if(returnCode != NSOKButton) return;
    
    NSNumber *picked = (NSNumber *)contextInfo;
    NSString *filename = [[sheet filenames] objectAtIndex:0];
    switch([picked intValue]) {
        case 0: {
            [self setJavaHome:filename];
            break;
        }
        case 1: {
            [self setCatalinaHome:filename];
            break;
        }
        case 2: {
            [self setCatalinaBase:filename];
            break;
        }
        default: break;
    }
    [picked release];
}

- (IBAction) editOpts:(id)sender {
    [entryWin setTitle:@"CATALINA_OPTS"];
    logDebug(@"setStringValue:%@",[catalinaOptsField stringValue]);
    [entryField setStringValue:[catalinaOptsField stringValue]];
    [entryWin makeKeyAndOrderFront:self];
}

- (IBAction) didEndEditOpts:(id)sender {
    [self setCatalinaOpts:[entryField stringValue]];
    [entryWin performClose:self];
}

- (IBAction) selectFont:(id)sender {
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction) changeFont:(id)sender {
    logDebug(@"changeFont: %@",sender);
    NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:consoleFont];
    [self setConsoleFont:newFont];
}

// ACCESSORS ================================================================ //


- (NSObjectController *)defCon {
    return defCon;
}

- (void)setDefCon:(NSObjectController *)newDefCon {
    [newDefCon retain];
    [defCon release];
    defCon = newDefCon;
}

- (BOOL)useShellEnv {
    return useShellEnv;
}

- (void)setUseShellEnv:(BOOL)newUseShellEnv {
    //logDebug(@"setUseShellEnv:%d",newUseShellEnv);
    useShellEnv = newUseShellEnv;
    if(newUseShellEnv) [self loadUserShellEnvironment:self]; 
    [[NSUserDefaults standardUserDefaults] setBool:newUseShellEnv 
                                            forKey:TCSUserDefaultsUseShellEnv];
}

- (NSMutableDictionary *)defaultVariables {
    return defaultVariables;
}

- (void)setDefaultVariables:(NSMutableDictionary *)newDefaultVariables {
    //logDebug(@"setDefaultVariables");
    [newDefaultVariables retain];
    [defaultVariables release];
    defaultVariables = newDefaultVariables;
    [self _saveDefaults];
}

- (NSColor *)backgroundColor {
    return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)newBackgroundColor {
    [newBackgroundColor retain];
    [backgroundColor release];
    backgroundColor = newBackgroundColor;
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:backgroundColor];
    [[NSUserDefaults standardUserDefaults] 
        setObject:colorAsData forKey:TCSUserDefaultsTextColorBackground];
}


- (NSColor *)stdoutColor {
    return stdoutColor;
}

- (void)setStdoutColor:(NSColor *)newStdoutColor {
    [newStdoutColor retain];
    [stdoutColor release];
    stdoutColor = newStdoutColor;
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:stdoutColor];
    [[NSUserDefaults standardUserDefaults] 
        setObject:colorAsData forKey:TCSUserDefaultsTextColorStdout];
}

- (NSColor *)stderrColor {
    return stderrColor;
}

- (void)setStderrColor:(NSColor *)newStderrColor {
    [newStderrColor retain];
    [stderrColor release];
    stderrColor = newStderrColor;
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:stderrColor];
    [[NSUserDefaults standardUserDefaults] 
        setObject:colorAsData forKey:TCSUserDefaultsTextColorStderr];
}

- (NSColor *)serverLogColor {
    return serverLogColor;
}

- (void)setServerLogColor:(NSColor *)newServerLogColor {
    [newServerLogColor retain];
    [serverLogColor release];
    serverLogColor = newServerLogColor;
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:serverLogColor];
    [[NSUserDefaults standardUserDefaults] 
        setObject:colorAsData forKey:TCSUserDefaultsTextColorServerLog];    
}

- (NSColor *)hostLogColor {
    return hostLogColor;
}

- (void)setHostLogColor:(NSColor *)newHostLogColor {
    [newHostLogColor retain];
    [hostLogColor release];
    hostLogColor = newHostLogColor;
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:hostLogColor];
    [[NSUserDefaults standardUserDefaults] 
        setObject:colorAsData forKey:TCSUserDefaultsTextColorHostLog];
}

- (NSFont *)consoleFont {
    return consoleFont;
}

- (void)setConsoleFont:(NSFont *)newConsoleFont {
    [newConsoleFont retain];
    [consoleFont release];
    consoleFont = newConsoleFont;
    NSData *fontAsData = [NSKeyedArchiver archivedDataWithRootObject:consoleFont];
    [[NSUserDefaults standardUserDefaults] 
        setObject:fontAsData forKey:TCSUserDefaultsConsoleFont];
}

- (NSString *) consoleFontName {
    return [consoleFont fontName];
}

- (BOOL)manualComponentUpdates {
    return manualComponentUpdates;
}

- (void)setManualComponentUpdates:(BOOL)newManualComponentUpdates {
    manualComponentUpdates = newManualComponentUpdates;
    [[NSUserDefaults standardUserDefaults]
        setBool:newManualComponentUpdates forKey:TCSUserDefaultsManualComponentUpdates];
}

- (NSNumber *)componentUpdatesEvery {
    return componentUpdatesEvery;
}

- (void)setComponentUpdatesEvery:(NSNumber *)newComponentUpdatesEvery {
    [newComponentUpdatesEvery retain];
    [componentUpdatesEvery release];
    componentUpdatesEvery = newComponentUpdatesEvery;
    [[NSUserDefaults standardUserDefaults]
        setObject:newComponentUpdatesEvery forKey:TCSUserDefaultsComponentUpdatesEvery];
}

- (BOOL)shouldMeow {
    return shouldMeow;
}

- (void)setShouldMeow:(BOOL)newShouldMeow {
    shouldMeow = newShouldMeow;
    [[NSUserDefaults standardUserDefaults]
        setBool:newShouldMeow forKey:TCSUserDefaultsShouldMeow];
}

- (BOOL)canUseAccessControlLists {
    return canUseAccessControlLists;
}

- (void)setCanUseAccessControlLists:(BOOL)newCanUseAccessControlLists {
    canUseAccessControlLists = newCanUseAccessControlLists;
    [[NSUserDefaults standardUserDefaults]
        setBool:newCanUseAccessControlLists forKey:TCSUserDefaultsCanSetACLs];
}

- (BOOL)canRunTomcatsPrivileged {
    return canRunTomcatsPrivileged;
}

- (void)setCanRunTomcatsPrivileged:(BOOL)newCanRunTomcatsPrivileged {
    canRunTomcatsPrivileged = newCanRunTomcatsPrivileged;
    [[NSUserDefaults standardUserDefaults]
        setBool:newCanRunTomcatsPrivileged forKey:TCSUserDefaultsCanRunTomcatsPrivileged];
}

- (BOOL)canRepairPermissions {
    return canRepairPermissions;
}

- (void)setCanRepairPermissions:(BOOL)newCanRepairPermissions {
    canRepairPermissions = newCanRepairPermissions;
    [[NSUserDefaults standardUserDefaults]
        setBool:newCanRepairPermissions forKey:TCSUserDefaultsCanRepairPermissions];
}




// DEPENDENT KEYS =========================================================== //

#pragma mark Environment Variables

- (NSString *)javaHome {
    return [defaultVariables objectForKey:TCSEnvKeyJavaHome];
}

- (void)setJavaHome:(NSString *)newJavaHome {
    [defaultVariables setObject:newJavaHome forKey:TCSEnvKeyJavaHome];
    [self _saveDefaults];
}

- (NSString *)catalinaHome {
    return [defaultVariables objectForKey:TCSEnvKeyCatalinaHome];
}

- (void)setCatalinaHome:(NSString *)newCatalinaHome {
    [defaultVariables setObject:newCatalinaHome forKey:TCSEnvKeyCatalinaHome];
    [self _saveDefaults];
}

- (NSString *)catalinaBase {
    return [defaultVariables objectForKey:TCSEnvKeyCatalinaBase];
}

- (void)setCatalinaBase:(NSString *)newCatalinaBase {
    [defaultVariables setObject:newCatalinaBase forKey:TCSEnvKeyCatalinaBase];
    [self _saveDefaults];
}

- (NSString *)catalinaOpts {
    return [defaultVariables objectForKey:TCSEnvKeyCatalinaOpts];
}

- (void)setCatalinaOpts:(NSString *)newCatalinaOpts {
    [defaultVariables setObject:newCatalinaOpts forKey:TCSEnvKeyCatalinaOpts];
    [self _saveDefaults];
}

- (NSString *)jpdaTransport {
    return [defaultVariables objectForKey:TCSEnvKeyJpdaTransport];
}

- (void)setJpdaTransport:(NSString *)newJpdaTransport {
    [defaultVariables setObject:newJpdaTransport forKey:TCSEnvKeyJpdaTransport];
    [self _saveDefaults];
}

- (NSString *)jpdaAddress {
    return [defaultVariables objectForKey:TCSEnvKeyJpdaAddress];
}

- (void)setJpdaAddress:(NSString *)newJpdaAddress {
    [defaultVariables setObject:newJpdaAddress forKey:TCSEnvKeyJpdaAddress];
    [self _saveDefaults];
}

- (NSColor *) colorForOutputType:(int)type {
    NSColor *color;
    switch (type) {
        case TCS_STDOUT: {
            color = [self stdoutColor];
            break;
        }
        case TCS_STDERR: {
            color = [self stderrColor];
            break;
        }
        case TCS_SERVER_LOG: {
            color = [self serverLogColor];
            break;
        }
        case TCS_HOST_LOG: {
            color = [self hostLogColor];
            break;
        }
        default: break;
    }
    return color;
}

- (NSColor *) colorForAttribute:(NSString *) attribute {
    NSColor *color = nil;
    if([attribute isEqualToString:TCSTemporaryAttributeStdOut])
        color = [self stdoutColor];
    if([attribute isEqualToString:TCSTemporaryAttributeStdErr])
        color = [self stderrColor];
    if([attribute isEqualToString:TCSTemporaryAttributeServerLog])
        color = [self serverLogColor];
    if([attribute isEqualToString:TCSTemporaryAttributeHostLog])
        color = [self hostLogColor];
    return color;
}

- (NSString *) attributeForOutputType:(int)type {
    NSString *attribute = nil;
    switch (type) {
        case TCS_STDOUT: {
            attribute = TCSTemporaryAttributeStdOut;
            break;
        }
        case TCS_STDERR: {
            attribute = TCSTemporaryAttributeStdErr;
            break;
        }
        case TCS_SERVER_LOG: {
            attribute = TCSTemporaryAttributeServerLog;
            break;
        }
        case TCS_HOST_LOG: {
            attribute = TCSTemporaryAttributeHostLog;
            break;
        }
        default: break;
    }
    return attribute;
}

- (void) _saveDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *defsAsData = [NSKeyedArchiver archivedDataWithRootObject:
        [NSMutableDictionary dictionaryWithDictionary:defaultVariables]];
    [defaults setObject:defsAsData forKey:TCSUserDefaultsDefaultValues];
}


// WINDOW CONTROLLER ======================================================== //

- (void) showWindow:(id)sender {
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)aNotification { 
    //TODO do I need to save to user defaults here?
}

- (void) windowDidLoad {
    [[self window] setFrameAutosaveName:TCSPrefWindowSaveName];
}

@end
