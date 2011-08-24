//
//  TCSToolbarDelegate.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSCatSlapper;
@class TCSController;

@interface TCSToolbarDelegate : NSObject {
    NSToolbar *toolbar;
    NSToolbarItem *toggleItem;
    
    IBOutlet TCSCatSlapper *slapper;
    IBOutlet NSArrayController *kittyController;
    IBOutlet TCSController *appController;
}

- (NSToolbar *)toolbar;
- (void)setToolbar:(NSToolbar *)newToolbar;

- (void) toggleToggleItem:(BOOL)isRunning;

- (void) registerObservations;
- (void) removeObservations;


@end
