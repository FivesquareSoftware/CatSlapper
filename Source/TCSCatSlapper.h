//
//  TCSCatSlapper.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/20/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;
@class TCSCatWrangler;
@class TCSController;
@class TCSConsoleView;
@class TCSTomcatManagerProxy;
@class TCSLaunchDaemonManager;

@interface TCSCatSlapper : NSObject  {
    NSMutableArray *kittens;
    int selectedKittyIndex;
    
    NSTimer *serverUpdateTimer;
    NSTimer *componentUpdateTimer;
    
    
    IBOutlet TCSController *appController;
    IBOutlet NSArrayController *kittyController;
    IBOutlet TCSCatWrangler *wrangler;
    IBOutlet TCSLaunchDaemonManager *launchDaemonManager;
    IBOutlet TCSTomcatManagerProxy *managerProxy;
    IBOutlet NSPopUpButton *kittySelector;
    IBOutlet NSTextField *kittyStatusText;
    IBOutlet TCSConsoleView *consoleView;
    IBOutlet NSOutlineView *componentView;
    IBOutlet NSPopUpButton *startupTypeSelector;
    
}

- (unsigned int)countOfKittens;
- (id)objectInKittensAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inKittensAtIndex:(unsigned int)index;
- (void)removeObjectFromKittensAtIndex:(unsigned int)index;
- (void)replaceObjectInKittensAtIndex:(unsigned int)index withObject:(id)anObject;

- (NSArray *) kittens;
- (TCSKitty *) selectedKitty;
- (int) nameInUse:(NSString *)aName;
- (void) reconfigureSelectedKittenFromServerConfig;
- (void) validateSelectedKitten;
- (void) showLogForSelectedKitten;
- (void) repairPermissionsForKitty:(TCSKitty *)tk;
- (void) repairPermissions;
- (void) syncLaunchdForKitty:(TCSKitty *)tk;
- (void) syncLaunchd;

- (IBAction) selectKitty:(id) sender;
- (IBAction) toggleKitty:(id) sender;
- (IBAction) restartKitty:(id) sender;
- (IBAction) updateComponentsForSelectedKitty:(id)sender;
- (void) updateComponentsForSelectedKitty;

- (void) registerObservations;
- (void) removeObservations;
- (void) cleanup;

@end
