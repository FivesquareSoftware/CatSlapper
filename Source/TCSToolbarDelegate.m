//
//  TCSToolbarDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSToolbarDelegate.h"
#import "TCSLogger.h"
#import "TCSKittyArrayController.h"



@implementation TCSToolbarDelegate

// STATIC VARS ============================================================== //

static NSString *TCSToolbarItemToggle = @"TCSToolbarItemToggle";
static NSString *TCSToolbarItemRestart = @"TCSToolbarItemRestart";
static NSString *TCSToolbarItemAdd = @"TCSToolbarItemAdd";
static NSString *TCSToolbarItemRemove = @"TCSToolbarItemRemove";
static NSString *TCSToolbarItemInfo = @"TCSToolbarItemInfo";
static NSString *TCSToolbarItemErrors = @"TCSToolbarItemErrors";
static NSString *TCSToolbarItemConsole = @"TCSToolbarItemConsole";
static NSString *TCSToolbarItemInstall = @"TCSToolbarItemInstall";
static NSString *TCSToolbarItemNext = @"TCSToolbarItemNext";
static NSString *TCSToolbarItemPrevious = @"TCSToolbarItemPrevious";


// OBJECT STUFF ============================================================= //

-(void) awakeFromNib {
    BOOL isRunning = [kittyController safeBoolValueForKeyPath:@"selection.isRunning"];
    [self toggleToggleItem:isRunning];
}

- (void) dealloc {
    [toolbar release];
    [super dealloc];
}


// ACCESSORS =============================================================== //

- (NSToolbar *)toolbar {
    return toolbar;
}

- (void)setToolbar:(NSToolbar *)newToolbar {
    [newToolbar retain];
    [toolbar release];
    toolbar = newToolbar;
}


// TOOLBAR DELEGATE ========================================================= //

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdent
 willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    
    if ([itemIdent isEqual:TCSToolbarItemToggle]) { 
        [toolbarItem setLabel: @"Toggle"];
        [toolbarItem setPaletteLabel: @"Toggle"];
        [toolbarItem setToolTip:@"Toggle"];

        [toolbarItem  setImage:[NSImage imageNamed:@"start"]];
        [toolbarItem setTarget: slapper];
        [toolbarItem setAction: @selector(toggleKitty:)];
        toggleItem = toolbarItem;
    
    } else if([itemIdent isEqual:TCSToolbarItemRestart]) {
        [toolbarItem setLabel: @"Restart"];
        [toolbarItem setPaletteLabel: @"Restart"];
        [toolbarItem setToolTip:@"Restart"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"restart"]];
        [toolbarItem setTarget: slapper];
        [toolbarItem setAction: @selector(restartKitty:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemAdd]) {
        [toolbarItem setLabel: @"Add"];
        [toolbarItem setPaletteLabel: @"Add"];
        [toolbarItem setToolTip:@"Add"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"add"]];
        [toolbarItem setTarget: kittyController];
        [toolbarItem setAction: @selector(add:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemRemove]) {
        [toolbarItem setLabel: @"Remove"];
        [toolbarItem setPaletteLabel: @"Remove"];
        [toolbarItem setToolTip:@"Remove"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"remove"]];
        [toolbarItem setTarget: kittyController];
        [toolbarItem setAction: @selector(remove:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemInfo]) {
        [toolbarItem setLabel: @"Info"];
        [toolbarItem setPaletteLabel: @"Info"];
        [toolbarItem setToolTip:@"Info"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"info"]];
        [toolbarItem setTarget: appController];
        [toolbarItem setAction: @selector(toggleInfo:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemConsole]) {
        [toolbarItem setLabel: @"Console"];
        [toolbarItem setPaletteLabel: @"Console"];
        [toolbarItem setToolTip:@"Console"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"screen"]];
        [toolbarItem setTarget: appController];
        [toolbarItem setAction: @selector(toggleConsole:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemInstall]) {
        [toolbarItem setLabel: @"Install"];
        [toolbarItem setPaletteLabel: @"Install"];
        [toolbarItem setToolTip:@"Install"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"installer"]];
        [toolbarItem setTarget: appController];
        [toolbarItem setAction: @selector(toggleInstaller:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemNext]) {
        [toolbarItem setLabel: @"Next"];
        [toolbarItem setPaletteLabel: @"Next"];
        [toolbarItem setToolTip:@"Next"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"arrowright"]];
        [toolbarItem setTarget: kittyController];
        [toolbarItem setAction: @selector(selectNext:)];
        
    } else if([itemIdent isEqual:TCSToolbarItemPrevious]) {
        [toolbarItem setLabel: @"Previous"];
        [toolbarItem setPaletteLabel: @"Previous"];
        [toolbarItem setToolTip:@"Previous"];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"arrowleft"]];
        [toolbarItem setTarget: kittyController];
        [toolbarItem setAction: @selector(selectPrevious:)];
        
    } else { 
        toolbarItem = nil;
    }
    
    return toolbarItem;
}


// return an array of the items found in the default toolbar
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar { 
    return [NSArray arrayWithObjects:
        TCSToolbarItemToggle, TCSToolbarItemRestart,
        TCSToolbarItemAdd, TCSToolbarItemRemove, TCSToolbarItemInstall,
        NSToolbarFlexibleSpaceItemIdentifier, 
        TCSToolbarItemPrevious, TCSToolbarItemNext,
        TCSToolbarItemConsole, TCSToolbarItemInfo, nil];
}

// return an array of all the items that can be put in the toolbar
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar { 
    return [NSArray arrayWithObjects:
        NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        TCSToolbarItemToggle, TCSToolbarItemRestart,
        TCSToolbarItemAdd, TCSToolbarItemRemove, 
        TCSToolbarItemInfo, TCSToolbarItemConsole,
        TCSToolbarItemInstall, TCSToolbarItemPrevious, 
        TCSToolbarItemNext, nil];
}

/*
// lets us modify items (target, action, tool tip, etc.) as they are added to toolbar
- (void)toolbarWillAddItem:(NSNotification *)notification {
    
}


// handle removal of items.  We have an item that could be a target, so that needs to be reset
- (void)toolbarDidRemoveItem:(NSNotification *)notification { 
    // NSToolbarItem *removedItem = [[notification userInfo] objectForKey: @"item"];
    
}
*/

- (void) toggleToggleItem:(BOOL)isRunning {
    NSString *imgName = (isRunning) ? @"stop" : @"start" ;
    [toggleItem setImage:[NSImage imageNamed:imgName]];
}


// OBSERVATIONS ============================================================= //

#pragma mark Observations

- (void) registerObservations {
    [kittyController addObserver:self
                      forKeyPath:@"selection.isRunning" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
}

- (void) removeObservations {
    [kittyController removeObserver:self forKeyPath:@"selection.isRunning"];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    if([keyPath isEqualToString:@"selection.isRunning"]) {
        BOOL isRunning = [kittyController safeBoolValueForKeyPath:keyPath];
        logDebug(@"kitty run state changed to %d",isRunning);
        [self toggleToggleItem:isRunning];
    }
}


@end
