//
//  TCSController.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/20/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSToolbarDelegate;
@class TCSCatSlapper;
@class TCSPrefController;
@class TCSConsoleView;
@class TCSKitty;

@interface TCSController : NSObject {
    //interface
    BOOL infoIsClosed;    
    BOOL consoleIsClosed;    
    NSSize minSizeClosed;
    NSSize minSizeOpen;

    IBOutlet NSWindow *mainWin;
    IBOutlet NSWindow *entryWin;
    IBOutlet NSWindow *licensePanel;
    IBOutlet NSWindow *registrationPanel;
    IBOutlet NSWindow *newVersionPanel;
    IBOutlet NSTextView *licenseTextView;
    IBOutlet NSMenuItem *toggleControllerMenuItem;
    IBOutlet NSMenuItem *toggleInstallerMenuItem;
    IBOutlet NSWindow *enableACLsPanel;
    IBOutlet NSWindow *okToRunPrivilegedPanel;
    IBOutlet NSWindow *okToRepairPermissionsPanel;

    IBOutlet NSToolbar *toolbar;
    IBOutlet TCSToolbarDelegate *toolbarDelegate;
    
    IBOutlet NSTabView *tabView;
    IBOutlet TCSConsoleView *consoleView;
    IBOutlet NSScrollView *consoleScrollView;
    
    IBOutlet NSTextField *catalinaOptsField;
    IBOutlet NSTextField *entryField;
    IBOutlet NSButton *toggleUseDefaultsSwitch;
        
    //model objects
    IBOutlet TCSCatSlapper *slapper;
    IBOutlet NSArrayController *kittyController;

    NSMenu *dockMenu;
    
    // alerts
    NSAlert *badRegInfoAlert;
    NSAlert *latestVersionAlert;
    NSAlert *cantUseSytemDaemonsAlert;
    NSAlert *enablingACLsFailedAlert;
    NSAlert *syncingLaunchDaemonsFailedAlert;
    NSAlert *repairingPermissionsFailedAlert;
    
}

- (void) drawBackground;
- (void) drawOpenInto:(NSImage *)bg;
- (void) drawClosedInto:(NSImage *)bg;    

- (IBAction) clearConsole:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) displayServerConfigErrors:(id)sender;
- (IBAction) selectServerTab:(id)sender;
- (IBAction) selectEnvironmentTab:(id)sender;
- (IBAction) selectComponentsTab:(id)sender;

- (IBAction) browse:(id)sender;
- (IBAction) editOpts:(id)sender;
- (IBAction) didEndEditOpts:(id)sender;
- (IBAction) toggleController:(id)sender;
- (IBAction) toggleInstaller:(id)sender;

- (IBAction) toggleInfo:(id)sender;
- (IBAction) toggleConsole:(id)sender;
- (IBAction) askUserIfWeCanInstallACLs:(id)sender;
- (IBAction) cancelACLInstall:(id)sender;
- (IBAction) proceedWithACLInstall:(id)sender;
- (IBAction) warnUserTheyCantUseSystemDaemons:(id)sender;
- (IBAction) warnUserThatEnablingACLsFailed:(id)sender;
- (IBAction) warnUserThatSyncingLaunchDaemonsFailed:(id)sender ;
- (IBAction) askUserIfWeCanRunPrivileged:(id)sender;
- (IBAction) cancelRunPrivileged:(id)sender;
- (IBAction) proceedToRunPrivileged:(id)sender;
- (IBAction) askUserIfWeCanRepairPermissions:(id)sender;
- (IBAction) cancelRepairPermissions:(id)sender;
- (IBAction) proceedToRepairPermissions:(id)sender;
- (IBAction) warnUserThatRepairingPermissionsFailed:(id)sender;

- (BOOL) MacOSPantherOrBetter;
- (BOOL) MacOSTigerOrBetter;
- (void) shutdownUnsupportedPlatform;
- (void) meow;
- (void) checkForNewVersion:(BOOL)forced;
- (void) signalNotification:(NSNotification *)notification;

- (IBAction) visitFivesquare:(id)sender;
- (IBAction) displayManagerHelp:(id)sender;
- (IBAction) displayACLHelp:(id)sender; 
- (IBAction) displayRunningPrivilegedHelp:(id)sender;
- (IBAction) displayRepairPermissionsHelp:(id)sender;
- (IBAction) openAcknowledgements:(id)sender;
- (IBAction) openLicense:(id)sender;
- (IBAction) openTomcatDocs:(id)sender;
- (IBAction) openRunningTomcat:(id)sender;
- (IBAction) openTomcatWebsite:(id)sender;
- (IBAction) sendCatSlapperFeedback:(id)sender;

- (IBAction) newVersionCheck:(id)sender;
- (IBAction) askUserIfWeCanGetNewVersion:(id)sender;
- (IBAction) cancelGetNewVersion:(id)sender;
- (IBAction) getNewVersion:(id)sender;
    

- (void) registerObservations;
- (void) removeObservations;    

@end
