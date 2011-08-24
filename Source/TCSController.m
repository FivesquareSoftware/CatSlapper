//
//  TCSController.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/20/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#define DEFAULT_WINDOW_WIDTH  524.00
#define DEFAULT_WINDOW_HEIGHT 565.00
//#define DEFAULT_WINDOW_HEIGHT 650.00


#import "TCSController.h"
#import "TCSController+Scripting.h"
#import "TCSController+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSNoPopupSelectionTransformer.h"
#import "TCSToolbarDelegate.h"
#import "TCSCatSlapper.h"
#import "TCSPrefController.h"
#import "TCSConsoleView.h"
#import "TCSServerErrorDisplayController.h"
#import "TCSInstallerController.h"
#import "TCSTomcatManagerAuthController.h"
#import "TCSComponent.h"
#import "TCSKitty.h"
#import "TCSAuthorizationHandler.h"
#import "TCSKittyArrayController.h"
#import "TCSIOUtils.h"

#import <ExceptionHandling/NSExceptionHandler.h>

@implementation TCSController

static NSSize maxConsoleOpenSize;
static NSSize maxInfoOpenSize;

// OBJECT STUFF ============================================================= //
#pragma mark Object Methods

+ (void) initialize {
    // defaults
    NSMutableDictionary *defs = [NSMutableDictionary dictionary];
    NSData *kittensAsData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
    [defs setObject:kittensAsData forKey:TCSUserDefaultsKittens];
    [defs setObject:[NSNumber numberWithInt:0] forKey:TCSUserDefaultsSelectedKitty];
    [defs setObject:[NSNumber numberWithInt:0] forKey:TCSUserDefaultsSelectedPrefPane];
    [defs setObject:[NSNumber numberWithBool:YES] forKey:TCSUserDefaultsUseShellEnv];
    NSSize size = NSMakeSize(DEFAULT_WINDOW_WIDTH,DEFAULT_WINDOW_HEIGHT);
    NSData *sizeData = [NSData dataWithBytes:&size length:sizeof(size)];
    [defs setObject:sizeData forKey:TCSUserDefaultsMaxInfoOpenSize];
    [defs setObject:sizeData forKey:TCSUserDefaultsMaxConsoleOpenSize];
    
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]];
    [defs setObject:colorData forKey:TCSUserDefaultsTextColorBackground];
        
    colorData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blueColor]];    
    [defs setObject:colorData forKey:TCSUserDefaultsTextColorStdout];
    
    colorData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor redColor]];
    [defs setObject:colorData forKey:TCSUserDefaultsTextColorStderr];
    
    colorData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]];
    [defs setObject:colorData forKey:TCSUserDefaultsTextColorServerLog];
    [defs setObject:colorData forKey:TCSUserDefaultsTextColorHostLog];
    
    NSData *fontData = [NSKeyedArchiver archivedDataWithRootObject:
                            [NSFont fontWithName:@"Monaco" size:10.00]];
    [defs setObject:fontData forKey:TCSUserDefaultsConsoleFont];
    
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsManualComponentUpdates];
    [defs setObject:[NSNumber numberWithInt:30] forKey:TCSUserDefaultsComponentUpdatesEvery];
    [defs setObject:[NSNumber numberWithBool:YES] forKey:TCSUserDefaultsShouldMeow];
    
    [defs setObject:@"" forKey:TCSUserDefaultsRegistrationCode];
    
    [defs setObject:[NSNumber numberWithBool:YES] forKey:TCSUserDefaultsShouldAskAboutSettingACLs];
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsDidSetACLs];
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsCanSetACLs];

    [defs setObject:[NSNumber numberWithBool:YES] forKey:TCSUserDefaultsShouldAskAboutRunningPrivileged];
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsCanRunTomcatsPrivileged];    
    
    [defs setObject:[NSNumber numberWithBool:YES] forKey:TCSUserDefaultsShouldAskAboutRepairingPermissions];
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsCanRepairPermissions];    
    [defs setObject:[NSNumber numberWithBool:NO] forKey:TCSUserDefaultsNewVersionCheck];
    
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defs];
    
    //register transformers
    [NSValueTransformer setValueTransformer:
        [[[TCSNoPopupSelectionTransformer alloc] init] autorelease]
                                    forName:@"TCSNoPopupSelection"];
    // change notifications
    [self setKeys:[NSArray arrayWithObjects:@"registrationCode",@"registrationName",nil] 
            triggerChangeNotificationsForDependentKey:@"validRegistrationCode"];
    [self setKeys:[NSArray arrayWithObjects:@"registrationCode",@"registrationName",nil] 
            triggerChangeNotificationsForDependentKey:@"registrationMessage"];
}


- (id) init {
    if(self = [super init]) {
        minSizeClosed = NSMakeSize(DEFAULT_WINDOW_WIDTH,140.00);
        minSizeOpen = NSMakeSize(DEFAULT_WINDOW_WIDTH,419.00); 
//        minSizeOpen = NSMakeSize(DEFAULT_WINDOW_WIDTH,504.00); 
        infoIsClosed = NO;
        consoleIsClosed = NO;
        logTrace(@"minSizeClose = (%f,%f)",minSizeClosed.width,minSizeClosed.height);
        logTrace(@"minSizeOpen = (%f,%f)",minSizeOpen.width,minSizeOpen.height);
    }
    return self;
}

- (void) awakeFromNib {   
    logDebug(@"awakeFromNib");
#ifdef DEBUG
    logDebug(@"setExceptionHandlingMask");
    [[NSExceptionHandler defaultExceptionHandler] 
        setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *sizeData = [defaults dataForKey:TCSUserDefaultsMaxInfoOpenSize];
    NSSize *sizePtr = &maxInfoOpenSize;
    sizePtr = (NSSize *)[sizeData bytes];
    maxInfoOpenSize = *sizePtr;
    
    sizeData = [defaults dataForKey:TCSUserDefaultsMaxConsoleOpenSize];
    sizePtr = (NSSize *)[sizeData bytes];
    maxConsoleOpenSize = *sizePtr;
    
    logDebug(@"initializing maxInfoOpenSize to (%f,%f)"
                       ,maxInfoOpenSize.width,maxInfoOpenSize.height);
    logDebug(@"initializing maxConsoleOpenSize to (%f,%f)"
                       ,maxConsoleOpenSize.width
                       ,maxConsoleOpenSize.height);

    // so we can add/remove at will
    [tabView retain];
    [consoleScrollView retain];

    [mainWin setFrameAutosaveName:TCSWindowSaveName];
    //Panther crashes if you leave this in
    if([mainWin respondsToSelector:@selector(setShowsToolbarButton)]) {
        [mainWin setShowsToolbarButton:NO];
    }
    [self _initToolbar];
    [self _initDockMenu];
    [self _initAlerts];
    
    [self drawBackground];
}

- (void) drawBackground {
    NSColor *bgColor = [mainWin backgroundColor];
    NSImage *bg = [[NSImage alloc] initWithSize:[mainWin frame].size];
    
    [bg lockFocus];
    
    // Composite current background color into bg
    [bgColor set];
    NSRectFill(NSMakeRect(0, 0, [bg size].width, [bg size].height));
    
    if(infoIsClosed) {
        [self drawClosedInto:bg];
    } else {
        [self drawOpenInto:bg];
    }
    
    [bg unlockFocus];
    [mainWin setBackgroundColor:[NSColor colorWithPatternImage:bg]];
    [bg release];
}

- (void) drawOpenInto:(NSImage *)bg {
    // Composite top
    NSImage *topImg = [NSImage imageNamed:@"bg_top"];
    NSRect topRect = NSMakeRect(0, [bg size].height - [topImg size].height //x,y
                                , [bg size].width, [topImg size].height); //w,h
    NSColor *topColor = [NSColor colorWithPatternImage:topImg];
    [topColor set];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint([bg size].width, [bg size].height)];
    NSRectFill(topRect);

    NSImage *middleTopImg = [NSImage imageNamed:@"bg_middle_top"];
    NSRect middleTopRect = NSMakeRect(0, [bg size].height - [topImg size].height - [middleTopImg size].height//x,y
                                      , [bg size].width, [middleTopImg size].height); //w,h
    NSColor *middleTopColor = [NSColor colorWithPatternImage:middleTopImg];
    [middleTopColor set];
    [[NSGraphicsContext currentContext] 
        setPatternPhase:NSMakePoint([bg size].width, [bg size].height - [topImg size].height)];
    NSRectFill(middleTopRect);
    
    NSImage *middleBottomImg = [NSImage imageNamed:@"bg_middle_bottom"];
    NSRect middleBottomRect = NSMakeRect(0, [bg size].height - [topImg size].height - [middleTopImg size].height - [middleBottomImg size].height//x,y
                                         , [bg size].width, [middleBottomImg size].height); //w,h
    NSColor *middleBottomColor = [NSColor colorWithPatternImage:middleBottomImg];
    [middleBottomColor set];
    [[NSGraphicsContext currentContext] 
        setPatternPhase:NSMakePoint([bg size].width, [bg size].height - [topImg size].height - [middleTopImg size].height)];
    NSRectFill(middleBottomRect);
    
    
    // Composite bottom
    NSImage *bottomImg = [NSImage imageNamed:@"bg_bottom"];
    NSRect bottomRect = NSMakeRect(0, 0, [bg size].width, [bottomImg size].height); //x,y,w,h
    NSColor *bottomColor = [NSColor colorWithPatternImage:bottomImg];
    [bottomColor set];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, [bottomImg size].height)];
    NSRectFill(bottomRect);
}

- (void) drawClosedInto:(NSImage *)bg {
    // Composite combined
    NSImage *combinedImg = [NSImage imageNamed:@"bg_combined"];
    NSRect combinedRect = NSMakeRect(0, [bg size].height - [combinedImg size].height //x,y
                                , [bg size].width, [combinedImg size].height); //w,h
    NSColor *combinedColor = [NSColor colorWithPatternImage:combinedImg];
    [combinedColor set];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint([bg size].width, [bg size].height)];
    NSRectFill(combinedRect);
}

- (void) dealloc {
    [tabView release];
    [consoleScrollView release];
    [dockMenu release];
    [badRegInfoAlert release];
    [latestVersionAlert release];
    [cantUseSytemDaemonsAlert release];
    [enablingACLsFailedAlert release];
    [syncingLaunchDaemonsFailedAlert release];
    [repairingPermissionsFailedAlert release];
    [super dealloc];
}


// IBACTIONS ================================================================ //
#pragma mark Interface Methods

- (IBAction) clearConsole:(id)sender {
    [consoleView clear];
}

- (IBAction) showPreferences:(id)sender {
    [[TCSPrefController sharedPrefController] showWindow:sender];
}

- (IBAction) displayServerConfigErrors:(id)sender {
    TCSServerErrorDisplayController *controller = 
            [TCSServerErrorDisplayController displayController];
    [[controller errorArrayController] 
            setContent:[kittyController valueForKeyPath:@"selection.validationErrors"]];
    [controller showWindow:self];
}

- (IBAction) selectServerTab:(id)sender {
    [tabView selectTabViewItemAtIndex:0];
}

- (IBAction) selectEnvironmentTab:(id)sender {
    [tabView selectTabViewItemAtIndex:1];
}

- (IBAction) selectComponentsTab:(id)sender {
    [tabView selectTabViewItemAtIndex:2];
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
                 modalForWindow:mainWin
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
        case 0: 
            [kittyController setValue:filename forKeyPath:@"selection.javaHome"];
            break;
        case 1: 
            [kittyController setValue:filename forKeyPath:@"selection.catalinaHome"];
            break;
        case 2: 
            [kittyController setValue:filename forKeyPath:@"selection.catalinaBase"];
            break;
        default: break;
    }
    [picked release];
}

- (IBAction) editOpts:(id)sender {
    [entryWin setTitle:@"CATALINA_OPTS"];
    [entryField setStringValue:[catalinaOptsField stringValue]];
    [entryWin makeKeyAndOrderFront:self];
}

- (IBAction) didEndEditOpts:(id)sender {
    [kittyController setValue:[entryField stringValue] forKeyPath:@"selection.catalinaOpts"];
    [entryWin performClose:self];
}

- (IBAction) toggleController:(id)sender {
    if([toggleControllerMenuItem state] == NSOnState) {
        [mainWin close];
        [toggleControllerMenuItem setState:NSOffState];
    } else {
        [mainWin makeKeyAndOrderFront:sender];
        [toggleControllerMenuItem setState:NSOnState];
    }
}

- (IBAction) toggleInstaller:(id)sender {
    if([toggleInstallerMenuItem state] == NSOnState) {
        [[TCSInstallerController sharedInstallerController] close];
        [toggleInstallerMenuItem setState:NSOffState];
    } else {
        [[TCSInstallerController sharedInstallerController] showWindow:sender];
        [toggleInstallerMenuItem setState:NSOnState];
    }
}

- (IBAction) toggleInfo:(id)sender {
    NSRect rect = [mainWin frame];
    
    NSSize realSize = rect.size;
    float rw = realSize.width;
    float rh = realSize.height;
    
    float minwclosed = minSizeClosed.width;
    float minhclosed = minSizeClosed.height;
    
    float minwopen = minSizeOpen.width;
    float minhopen = minSizeOpen.height;
    
    //    NSSize maxSize = [mainWin maxSize];
    //    NSSize maxSize = NSMakeSize(maxWindowWidth,maxWindowHeight);
    float maxw = maxInfoOpenSize.width;
    float maxh = maxInfoOpenSize.height;
    
    NSMenuItem *infoItem = [[[[NSApp mainMenu] itemWithTitle:@"View"] submenu] itemWithTitle:@"Toggle Info"];
    
    if(rw > minwclosed || rh > minhclosed) {
        //we're open, so now we close
        infoIsClosed = YES;
        [tabView removeFromSuperview];
        [consoleScrollView removeFromSuperview];

// Apple bug? See below.
//        [mainWin setMinSize:minSizeClosed];
//        logDebug(@"mainWin.minSize(w,h) = (%f,%f)",[mainWin minSize].width,[mainWin minSize].height);

        rect.origin.y = rect.origin.y+(rh-minhclosed);
        rect.size = minSizeClosed;
        logDebug(@"closing info to size(%f,%f)",minwclosed,minhclosed);
        [mainWin setShowsResizeIndicator:NO];
        [mainWin setFrame:rect display:YES animate:NO];
        [infoItem setState:NSOffState];
    } else {
        //we're closed, so now we open
        infoIsClosed = NO;
        rect.origin.y = rect.origin.y+(rh-maxh);
        rect.size = maxInfoOpenSize;
        logDebug(@"opening info to size(%f,%f)",maxw,maxh);
        [mainWin setFrame:rect display:YES animate:NO];
        
        [[mainWin contentView] addSubview:tabView];
        float tvy = maxh-([tabView frame].size.height + 132.00);
        //        [tabView setFrameOrigin:NSMakePoint(13,tvy)];
        [tabView setFrameOrigin:NSMakePoint(-11,tvy)];
        [[mainWin contentView] addSubview:consoleScrollView];
        float cby = maxh-([consoleScrollView frame].size.height + [tabView frame].size.height + 135.00);
        //        [consoleScrollView setFrameOrigin:NSMakePoint(19,cby)];        
        [consoleScrollView setFrameOrigin:NSMakePoint(0,cby)];        

        [infoItem setState:NSOnState];

/* Apple Bug?  Sometimes this method sets the minSize minus the toolbar height (like here)
            other times it sets the minSize including the toolbar height.  Bizarre. */
//        logDebug(@"setting minSize (%f,%f)",minSizeOpen.width,minSizeOpen.height);
//        [mainWin setMinSize:minSizeOpen];
//        logDebug(@"mainWin.minSize(w,h) = (%f,%f)",[mainWin minSize].width,[mainWin minSize].height);
        
        [mainWin setShowsResizeIndicator:YES];
    }
}

- (IBAction) toggleConsole:(id)sender {
    if(infoIsClosed) return;
    
    NSRect rect = [mainWin frame];
    
    NSSize realSize = rect.size;
    float rw = realSize.width;
    float rh = realSize.height;
    
    float minwopen = minSizeOpen.width;
    float minhopen = minSizeOpen.height;
    
    float maxw = maxConsoleOpenSize.width;
    float maxh = maxConsoleOpenSize.height;
    if (maxh == minSizeOpen.height) {
        maxh = DEFAULT_WINDOW_HEIGHT;
    }
    
    NSMenuItem *consoleItem = [[[[NSApp mainMenu] 
                                    itemWithTitle:@"View"] submenu] 
                                        itemWithTitle:@"Toggle Info"];
    if(rh > minhopen) {
        //close console
        consoleIsClosed = YES;
        rect.origin.y = rect.origin.y+(rh-minhopen);
        rect.size = minSizeOpen;
        rect.size.width = rw;
        logDebug(@"closing console to rect (%f,%f,%f,%f)"
                 ,rect.origin.x,rect.origin.y
                 ,minSizeOpen.width,minSizeOpen.height);
        [mainWin setFrame:rect display:YES animate:YES];
        [consoleItem setState:NSOffState];
    } else {
        //open console
        consoleIsClosed = NO;
        
        rect.size = maxConsoleOpenSize;
        rect.origin.y = rect.origin.y+(rh-maxh);
        logDebug(@"opening console to rect (%f,%f,%f,%f)"
                 ,rect.origin.x,rect.origin.y
                 ,maxConsoleOpenSize.width,maxConsoleOpenSize.height);
        [mainWin setFrame:rect display:YES animate:YES];        
        [consoleItem setState:NSOnState];
    }
}


// ACL INTERROGATION ========================================================= //

#pragma mark ACL Methods

- (IBAction) askUserIfWeCanInstallACLs:(id)sender {
    logDebug(@"askUserIfWeCanInstallACLs");
    [NSApp beginSheet:enableACLsPanel
       modalForWindow:mainWin
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    [NSApp runModalForWindow:mainWin];
}


- (IBAction) cancelACLInstall:(id)sender {
    logDebug(@"cancelACLInstall");
    [NSApp endSheet:enableACLsPanel];
    [enableACLsPanel orderOut:self];
    [[TCSPrefController sharedPrefController] setCanUseAccessControlLists:NO];
    [NSApp stopModal];
}

- (IBAction) proceedWithACLInstall:(id)sender {
    logDebug(@"proceedWithACLInstall");
    [NSApp endSheet:enableACLsPanel];
    [enableACLsPanel orderOut:self];    
    [[TCSPrefController sharedPrefController] setCanUseAccessControlLists:YES];
    [NSApp stopModal];
}

- (IBAction) warnUserTheyCantUseSystemDaemons:(id)sender {
    [cantUseSytemDaemonsAlert beginSheetModalForWindow:mainWin 
                                         modalDelegate:self 
                                        didEndSelector:NULL 
                                           contextInfo:nil];
}

- (IBAction) warnUserThatEnablingACLsFailed:(id)sender {
    [enablingACLsFailedAlert beginSheetModalForWindow:mainWin 
                                        modalDelegate:self 
                                       didEndSelector:NULL 
                                          contextInfo:nil];
}

- (IBAction) warnUserThatSyncingLaunchDaemonsFailed:(id)sender {
    [syncingLaunchDaemonsFailedAlert beginSheetModalForWindow:mainWin 
                                        modalDelegate:self 
                                       didEndSelector:NULL 
                                          contextInfo:nil];
}

// RUN PRIVILEGED INTERROGATION ============================================= //

#pragma mark Run Privileged Methods

- (IBAction) askUserIfWeCanRunPrivileged:(id)sender {
    logDebug(@"askUserIfWeCanRunPrivileged");
    [NSApp beginSheet:okToRunPrivilegedPanel
       modalForWindow:mainWin
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    [NSApp runModalForWindow:mainWin];
}


- (IBAction) cancelRunPrivileged:(id)sender {
    [NSApp endSheet:okToRunPrivilegedPanel];
    [okToRunPrivilegedPanel orderOut:self];    
    [[TCSPrefController sharedPrefController] setCanRunTomcatsPrivileged:NO];
    [NSApp stopModal];
}

- (IBAction) proceedToRunPrivileged:(id)sender {
    [NSApp endSheet:okToRunPrivilegedPanel];
    [okToRunPrivilegedPanel orderOut:self];    
    [[TCSPrefController sharedPrefController] setCanRunTomcatsPrivileged:YES];
    [NSApp stopModal];
}


// REPAIR PERMISSIONS INTERROGATION ========================================= //

#pragma mark Repair Permissions Methods

- (IBAction) askUserIfWeCanRepairPermissions:(id)sender {
    logDebug(@"askUserIfWeCanRepairPermissions");
    [NSApp beginSheet:okToRepairPermissionsPanel
       modalForWindow:mainWin
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    [NSApp runModalForWindow:mainWin];
}

- (IBAction) cancelRepairPermissions:(id)sender {
    [NSApp endSheet:okToRepairPermissionsPanel];
    [okToRepairPermissionsPanel orderOut:self];    
    [[TCSPrefController sharedPrefController] setCanRepairPermissions:NO];
    [NSApp stopModal];
}

- (IBAction) proceedToRepairPermissions:(id)sender {
    [NSApp endSheet:okToRepairPermissionsPanel];
    [okToRepairPermissionsPanel orderOut:self];    
    [[TCSPrefController sharedPrefController] setCanRepairPermissions:YES];
    [NSApp stopModal];
}

- (IBAction) warnUserThatRepairingPermissionsFailed:(id)sender {
    [repairingPermissionsFailedAlert beginSheetModalForWindow:mainWin 
                                                modalDelegate:self 
                                               didEndSelector:NULL 
                                                  contextInfo:nil];
}

// WINDOW DELEGATE ========================================================== //

#pragma mark Window delegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize {
    logDebug(@"proposedFrameSize.size(w,h) = (%f,%f)"
                       ,proposedFrameSize.width,proposedFrameSize.height);
    float psw = proposedFrameSize.width;
    float psh = proposedFrameSize.height;
    if(infoIsClosed) {
        logDebug(@"returning minSizeClosed(w,h) = (%f,%f)",minSizeClosed.width,minSizeClosed.height);
        proposedFrameSize = minSizeClosed;
    } else {
        if(psh < minSizeOpen.height)
            proposedFrameSize.height = minSizeOpen.height;
    }
    return proposedFrameSize;
}

- (void) windowDidResize:(NSNotification *)notification {
    NSSize actualSize = [mainWin frame].size;
    logDebug(@"mainWin.frame.size(w,h) = (%f,%f)",actualSize.width,actualSize.height);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSSize maxSize = NSMakeSize(actualSize.width,actualSize.height);
    NSData *sizeData = [NSData dataWithBytes:&maxSize length:sizeof(maxSize)];
    if(!infoIsClosed) {
        logDebug(@"recording maxInfoOpenSize");
        maxInfoOpenSize = maxSize;
        [defaults setObject:sizeData forKey:TCSUserDefaultsMaxInfoOpenSize];
    }
    if(!consoleIsClosed) {
        logDebug(@"recording maxConsoleOpenSize");
        maxConsoleOpenSize = maxSize;
        [defaults setObject:sizeData forKey:TCSUserDefaultsMaxConsoleOpenSize];
    }
    [self drawBackground];
}

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame {
    [self toggleInfo:self];
    return NO;
}

- (BOOL) windowShouldClose:(id)sender {
    logTrace(@"windowShouldClose:%@",sender);
    if([sender isEqual:mainWin]) {
        [self toggleController:self];
    }
    return NO;
}

// APP DELEGATE ============================================================= //

#pragma mark Application Delegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    logDebug(@"applicationWillFinishLaunching");
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {    
    logDebug(@"applicationDidFinishLaunching");
    
    [slapper registerObservations];
    [toolbarDelegate registerObservations];
    [self registerObservations];
    // ends up being a pain because it asks for admin credentials at startup
    //[slapper repairPermissions];
    [slapper syncLaunchd];
    logDebug(@"Set initial toolbar run state");
    [toolbarDelegate toggleToggleItem:
        [kittyController safeBoolValueForKeyPath:@"selection.isRunning"]];
    [[TCSTomcatManagerAuthController sharedAuthController] setMainWindow:mainWin];
    [self meow];
    [self checkForNewVersion:NO];
}
 
- (BOOL) MacOSPantherOrBetter {
    UInt32 response;
    return ( Gestalt(gestaltSystemVersion, (SInt32 *) &response) == noErr)
        && (response >= 0x01030 );
}

- (BOOL) MacOSTigerOrBetter {
    UInt32 response;
    return ( Gestalt(gestaltSystemVersion, (SInt32 *) &response) == noErr)
        && (response >= 0x01040 );
}

- (void) shutdownUnsupportedPlatform {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:NSLocalizedString(@"TCSController.unsupportedOSMessage",nil)];
    [alert setInformativeText:NSLocalizedString(@"TCSController.unsupportedOSInfo",nil)];
    [alert setShowsHelp:NO];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert runModal];
    [NSApp terminate:self];
}

- (void) checkForNewVersion:(BOOL)forced {
    logDebug(@"checkForNewVersion:");
    if([[NSUserDefaults standardUserDefaults] boolForKey:TCSUserDefaultsNewVersionCheck] || forced) {
        id newestVersion = 
            [NSDictionary dictionaryWithContentsOfURL:
                [NSURL URLWithString:TCSURLFivesquareCatSlapperNewestVersion]];
        logDebug(@"newestVersion = %@",newestVersion);
        if(newestVersion != nil) {
            //CFBundleIdentifier //com.fivesquaresoftware.CatSlapper
            NSString *newIdentifier = [newestVersion objectForKey:@"CFBundleIdentifier"];
            //CFBundleShortVersionString //1.1.1
            NSString *newVersion = [newestVersion objectForKey:@"CFBundleShortVersionString"];
            //CFBundleVersion //v44
            NSString *newBuild = [newestVersion objectForKey:@"CFBundleVersion"];
            
            NSBundle *myBundle = [NSBundle mainBundle];
            NSString *identifier = 
                [myBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
            NSString *version = 
                [myBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *build = 
                [myBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
            logDebug(@"identifier = %@",identifier);
            logDebug(@"version = %@",version);
            logDebug(@"build = %@",build);
            logDebug(@"newBuild = %@",newBuild);
            if([identifier isEqualToString:newIdentifier]) {
                if([build length] > 1) {
                    //compare versions
                    NSString *buildNumberString = [build substringWithRange:NSMakeRange(1,[build length]-1)];
                    NSString *newBuildNumberString = [newBuild substringWithRange:NSMakeRange(1,[newBuild length]-1)];
                    int buildInt = [buildNumberString intValue];
                    int newBuildInt = [newBuildNumberString intValue];
                    if(newBuildInt > buildInt) {
                        logDebug(@"There is a new version!");
                        [self askUserIfWeCanGetNewVersion:self];
                    } else {
                        logDebug(@"This is the latest version!");
                        if(forced) {
                            [latestVersionAlert runModal];
                        }
                    }
                }
            }
        }
        
    }
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    logDebug(@"applicationWillResignActive:");
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
    [[dockMenu itemWithTag:DOCK_MENU_KITTY_ITEM_TAG] 
            setTitle:[kittyController valueForKeyPath:@"selection.name"]];
    logDebug(@"applicationWillBecomeActive");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [consoleView terminateAllServers:YES];
    [slapper removeObservations];
    [slapper cleanup];
    [toolbarDelegate removeObservations];
    [self removeObservations];
}

- (void) signalNotification:(NSNotification *)notification {
    logDebug(@"caught signal notifcation");
    [NSApp terminate:self];
}

- (NSMenu *) applicationDockMenu:(NSApplication *)sender {
    logDebug(@"applicationDockMenu:");
    return dockMenu;
}


// HELP MENU ACTIONS ======================================================== //
#pragma mark User Help Methods

- (IBAction) visitFivesquare:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TCSURLFivesquareWebsite]];
}

- (IBAction) displayManagerHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpManagerAnchor 
                    inBook:TCSCatSlapperHelpBook];
}

- (IBAction) displayACLHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpACLAnchor 
                    inBook:TCSCatSlapperHelpBook];
}

- (IBAction) displayRunningPrivilegedHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpRunningPrivilegedAnchor 
                    inBook:TCSCatSlapperHelpBook];
}

- (IBAction) displayRepairPermissionsHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpRepairPermissionsAnchor 
                    inBook:TCSCatSlapperHelpBook];
}

- (IBAction) openAcknowledgements:(id)sender {
    NSString *ackFilePath = [[NSBundle mainBundle] pathForResource:TCSAcknowledgementsFile ofType:@"rtf"];
    [licenseTextView readRTFDFromFile:ackFilePath];
    [licensePanel makeKeyAndOrderFront:self];
    [licensePanel setTitle:@"CatSlapper Acknowledgements"];
    [licenseTextView setNeedsDisplay:YES];
}

- (IBAction) openLicense:(id)sender {
    NSString *licenseFilePath = [[NSBundle mainBundle] pathForResource:TCSLicenseFile ofType:@"rtf"];
    [licenseTextView readRTFDFromFile:licenseFilePath];
    [licensePanel makeKeyAndOrderFront:self];
    [licensePanel setTitle:@"CatSlapper License"];
    [licenseTextView setNeedsDisplay:YES];
}

- (IBAction) openTomcatDocs:(id)sender {
    NSString *docsUrlString = @"http://localhost:";
    docsUrlString = [docsUrlString 
                        stringByAppendingString:
        [[slapper selectedKitty] defaultHttpPort]];
    docsUrlString = [docsUrlString stringByAppendingString:@"/tomcat-docs"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:docsUrlString]];
}

- (IBAction) openRunningTomcat:(id)sender {
    NSString *runingFilePath = [[NSBundle mainBundle] pathForResource:TCSTomcatRunningTomcatFile ofType:@"txt"];
    [licenseTextView readRTFDFromFile:runingFilePath];
    [licensePanel makeKeyAndOrderFront:self];
    [licensePanel setTitle:@"Running Tomcat"];
    [licenseTextView setNeedsDisplay:YES];
}

- (IBAction) openTomcatWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TCSURLTomcatOnlineDocs]];
}

- (IBAction) sendCatSlapperFeedback:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:TCSURLFivesquareCatslapperFeedback]];
}




// GET NEW VERSION INTERROGATION ============================================ //

#pragma mark Get New Version Methods

- (IBAction) newVersionCheck:(id)sender {
    [self checkForNewVersion:YES];
}

- (IBAction) askUserIfWeCanGetNewVersion:(id)sender {
    logDebug(@"askUserIfWeCanGetNewVersion");
    [NSApp runModalForWindow:newVersionPanel];
}

- (IBAction) cancelGetNewVersion:(id)sender {
    [newVersionPanel orderOut:self];    
    [NSApp stopModal];
}

- (IBAction) getNewVersion:(id)sender {
    [newVersionPanel orderOut:self];    
    [self visitFivesquare:self];
    [NSApp stopModal];
}


// TOOLBAR TARGET =========================================================== //

#pragma mark Toolbar target

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem { 
	return YES;
}

// MENU DELEGATE ============================================================ //

#pragma mark Menu Delegate

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
    logTrace(@"validateMenuItem:%@",menuItem);
    NSString *menuTitle = [menuItem title];
        
    BOOL valid = YES;
    if([menuTitle isEqualToString:@"Local Tomcat Documentation"]) {
        logDebug(@"Local Tomcat Documentation");
        TCSKitty *tk = [slapper selectedKitty];
        if(tk != nil) {
            if(![tk isRunning] 
               || [tk defaultHttpPort] == nil
               || [[tk defaultHttpPort] isEqualToString:@""]) {
                valid = NO;
            } else {
                TCSComponent *localhost = [tk componentWithName:@"localhost"];
                if(localhost == nil 
                   || [localhost componentWithName:@"tomcat-docs"] == nil) {
                    valid = NO;
                }
            }
        } else {
            valid = NO;
        }
    }
    //if([menuTitle isEqualToString:@"Register..."]) {
    //    if(ibe()) valid = NO;
    //}
    return valid;
}



 
// OBSERVATIONS ============================================================= //

#pragma mark Observations

- (void) registerObservations {
    [kittyController addObserver:self
                      forKeyPath:@"selection.name" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(signalNotification:) 
                                                 name:@"TCSNotifcationSignalCaught"
                                               object:nil];        
}

- (void) removeObservations {
    [kittyController removeObserver:self forKeyPath:@"selectionIndex"];    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    logDebug(@"observeValueForKeyPath:%@",keyPath);
    if([keyPath isEqualToString:@"selection.name"]) {
        [[dockMenu itemWithTag:DOCK_MENU_KITTY_ITEM_TAG] 
            setTitle:[kittyController valueForKeyPath:@"selection.name"]];
    }
}

@end


// SCRIPTING SUPPORT ======================================================== //

@implementation TCSController (Scripting)

- (BOOL)application:(NSApplication *)sender 
 delegateHandlesKey:(NSString *)key {
    logDebug(@"delegateHandlesKey:%@",key);
    if ([key isEqual:@"kittens"]
        || [key isEqual:@"selectedKitty"] ) {
        return YES;
    } else {
        return NO;
    }
}

- (TCSKitty *) selectedKitty {
    logDebug(@"selectedKitty = %@",[slapper selectedKitty]);
    return [slapper selectedKitty];
}

- (id) handleToggleSelectionScriptCommand:(NSScriptCommand *)command {
    logDebug(@"handleToggleSelectionScriptCommand:%@",command);
    [slapper toggleKitty:self];
    return nil;
}

- (id) handleRestartSelectionScriptCommand:(NSScriptCommand *)command {
    logDebug(@"handleRestartSelectionScriptCommand:%@",command);
    [slapper restartKitty:self];
    return nil;
}

@end


// PRIVATE ======================================================== //

@implementation TCSController (Private)


- (void) _initToolbar {
    toolbar = [[NSToolbar alloc] initWithIdentifier:TCSToolbarIdentifier];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setDelegate:toolbarDelegate];
    [mainWin setToolbar:toolbar];
    [toolbarDelegate setToolbar:toolbar];
    [toolbar release];    
}

- (void) _initDockMenu {
    dockMenu = [[NSMenu alloc] initWithTitle:@"CatSlapper"];
    [dockMenu setDelegate:slapper];
    NSMenuItem *catItem = 
        [[NSMenuItem alloc] 
                initWithTitle:@"" 
                       action:@selector(updateDockMenu:) keyEquivalent:@""];
    [catItem setTarget:slapper];
    [catItem setTag:DOCK_MENU_KITTY_ITEM_TAG];
    [dockMenu addItem:catItem];
    
    NSMenu *catMenu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *toggleItem = 
        [[NSMenuItem alloc] 
                initWithTitle:@"Toggle" 
                       action:@selector(toggleKitty:) keyEquivalent:@""];
    [toggleItem setTag:DOCK_MENU_TOGGLE_ITEM_TAG];
    [toggleItem setTarget:slapper];
    [catMenu addItem:toggleItem];
    
    NSMenuItem *restartItem = 
        [[NSMenuItem alloc] 
                initWithTitle:@"Restart" 
                       action:@selector(restartKitty:) keyEquivalent:@""];
    [restartItem setTag:DOCK_MENU_RESTART_ITEM_TAG];
    [restartItem setTarget:slapper];
    [catMenu addItem:restartItem];
    
    [dockMenu setSubmenu:catMenu forItem:catItem];    
}

- (void) _initAlerts {
    /*
    enableACLsAlert = [[NSAlert alloc] init];
    NSButton *yesButton = [enableACLsAlert addButtonWithTitle:@"OK"];
    [enableACLsAlert addButtonWithTitle:@"Cancel"];
    NSButton *notAgainCheckbox = [enableACLsAlert addButtonWithTitle:@"Don't ask again"];
    [notAgainCheckbox setButtonType:NSSwitchButton];
    [enableACLsAlert setMessageText:NSLocalizedString(@"TCSCatSlapper.OKToEnableACLsMessage",nil)];
    [enableACLsAlert setInformativeText:NSLocalizedString(@"TCSController.OKToEnableACLsInfo",nil)];
    [enableACLsAlert setShowsHelp:NO];
    [enableACLsAlert setAlertStyle:NSWarningAlertStyle];    
    */
    
    //warn of bd reg info
    badRegInfoAlert = [[NSAlert alloc] init];
    [badRegInfoAlert addButtonWithTitle:@"OK"];
    [badRegInfoAlert setMessageText:NSLocalizedString(@"TCSController.invalidRegistrationCodeMessage",nil)];
    [badRegInfoAlert setInformativeText:NSLocalizedString(@"TCSController.invalidRegistrationCodeInfo",nil)];
    [badRegInfoAlert setShowsHelp:NO];
    [badRegInfoAlert setAlertStyle:NSWarningAlertStyle];

    latestVersionAlert = [[NSAlert alloc] init];
    [latestVersionAlert addButtonWithTitle:@"OK"];
    [latestVersionAlert setMessageText:NSLocalizedString(@"TCSController.latestVersionMessage",nil)];
    [latestVersionAlert setInformativeText:NSLocalizedString(@"TCSController.latestVersionInfo",nil)];
    [latestVersionAlert setShowsHelp:NO];
    [latestVersionAlert setAlertStyle:NSInformationalAlertStyle];
    
    
    // warn user that they cannot use system daemons without ACL's enabled
    cantUseSytemDaemonsAlert = [[NSAlert alloc] init];
    [cantUseSytemDaemonsAlert addButtonWithTitle:@"OK"];
    [cantUseSytemDaemonsAlert setMessageText:NSLocalizedString(@"TCSController.cantUseSystemDaemonsMessage",nil)];
    [cantUseSytemDaemonsAlert setInformativeText:NSLocalizedString(@"TCSController.cantUseSystemDaemonsInfo",nil)];
    [cantUseSytemDaemonsAlert setShowsHelp:YES];
    [cantUseSytemDaemonsAlert setHelpAnchor:TCSCatSlapperHelpACLAnchor];
    [cantUseSytemDaemonsAlert setAlertStyle:NSWarningAlertStyle];    


    enablingACLsFailedAlert = [[NSAlert alloc] init];
    [enablingACLsFailedAlert addButtonWithTitle:@"OK"];
    [enablingACLsFailedAlert setMessageText:NSLocalizedString(@"TCSController.enablingACLsFailedMessage",nil)];
    [enablingACLsFailedAlert setInformativeText:NSLocalizedString(@"TCSController.enablingACLsFailedInfo",nil)];
    [enablingACLsFailedAlert setShowsHelp:YES];
    [enablingACLsFailedAlert setHelpAnchor:TCSCatSlapperHelpACLAnchor];
    [enablingACLsFailedAlert setAlertStyle:NSWarningAlertStyle];    
    
    /*
    aboutToRunPrivilegedAlert = [[NSAlert alloc] init];
    [aboutToRunPrivilegedAlert addButtonWithTitle:@"OK"];
    [aboutToRunPrivilegedAlert addButtonWithTitle:@"Cancel"];
    [aboutToRunPrivilegedAlert setMessageText:NSLocalizedString(@"TCSController.aboutToRunPrivilegedMessage",nil)];
    [aboutToRunPrivilegedAlert setInformativeText:NSLocalizedString(@"TCSController.aboutToRunPrivilegedInfo",nil)];
    [aboutToRunPrivilegedAlert setShowsHelp:NO];
    [aboutToRunPrivilegedAlert setAlertStyle:NSWarningAlertStyle];    
    */
    
    syncingLaunchDaemonsFailedAlert = [[NSAlert alloc] init];
    [syncingLaunchDaemonsFailedAlert addButtonWithTitle:@"OK"];
    [syncingLaunchDaemonsFailedAlert setMessageText:NSLocalizedString(@"TCSController.syncingLaunchDaemonsFailedMessage",nil)];
    [syncingLaunchDaemonsFailedAlert setInformativeText:NSLocalizedString(@"TCSController.syncingLaunchDaemonsFailedInfo",nil)];
    [syncingLaunchDaemonsFailedAlert setShowsHelp:YES];
    [syncingLaunchDaemonsFailedAlert setHelpAnchor:TCSCatSlapperHelpLaunchDaemonsAnchor];
    [syncingLaunchDaemonsFailedAlert setAlertStyle:NSWarningAlertStyle];    
    
    
    repairingPermissionsFailedAlert = [[NSAlert alloc] init];
    [repairingPermissionsFailedAlert addButtonWithTitle:@"OK"];
    [repairingPermissionsFailedAlert setMessageText:NSLocalizedString(@"TCSController.repairingPermissionsFailedMessage",nil)];
    [repairingPermissionsFailedAlert setInformativeText:NSLocalizedString(@"TCSController.repairingPermissionsFailedInfo",nil)];
    [repairingPermissionsFailedAlert setShowsHelp:YES];
    [repairingPermissionsFailedAlert setHelpAnchor:TCSCatSlapperHelpRepairPermissionsAnchor];
    [repairingPermissionsFailedAlert setAlertStyle:NSWarningAlertStyle];    
    
}


@end

