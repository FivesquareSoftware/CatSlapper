//
//  TCSPrefsToolbarDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 4/25/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSPrefsToolbarDelegate.h"
#import "TCSLogger.h"
#import "TCSConstants.h"


@implementation TCSPrefsToolbarDelegate

// STATIC VARS ============================================================== //

static NSString *TCSPrefsToolbarIdentifier = @"TCSPrefsToolbarIdentifier";
static NSString *TCSPrefsToolbarItemAppearance = @"TCSPrefsToolbarItemAppearance";
static NSString *TCSPrefsToolbarItemDefaults = @"TCSPrefsToolbarItemDefaults";
static NSString *TCSPrefsToolbarItemManager = @"TCSPrefsToolbarItemManager";

// OBJECT STUFF ============================================================= //

-(void) awakeFromNib {
    //create toolbar, window retains
    toolbar = [[NSToolbar alloc] initWithIdentifier:TCSPrefsToolbarIdentifier];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setDelegate:self];
    
    NSArray *items = 
        [NSArray arrayWithObjects: TCSPrefsToolbarItemAppearance
            , TCSPrefsToolbarItemDefaults
            , TCSPrefsToolbarItemManager,  nil];
    int idx = [[NSUserDefaults standardUserDefaults] integerForKey:TCSUserDefaultsSelectedPrefPane];
    [toolbar setSelectedItemIdentifier:[items objectAtIndex:idx]];
    [tabView selectTabViewItemAtIndex:idx];
    
    [prefsWindow setToolbar:toolbar];
    [self _resizeForIndex:idx];
}

- (void) dealloc {
    [super dealloc];
}



// TOOLBAR DELEGATE ========================================================= //

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdent
 willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    
    if ([itemIdent isEqual:TCSPrefsToolbarItemAppearance]) { 
        [toolbarItem setLabel: @"General"];
        [toolbarItem setPaletteLabel: @"General"];
        [toolbarItem setToolTip:@"General"];
        [toolbarItem setTag:0];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"appearance"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(showPane:)];
        
    } else if([itemIdent isEqual:TCSPrefsToolbarItemDefaults]) {
        [toolbarItem setLabel: @"Defaults"];
        [toolbarItem setPaletteLabel: @"Defaults"];
        [toolbarItem setToolTip:@"Defaults"];
        [toolbarItem setTag:1];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"default"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(showPane:)];
        
    } else if([itemIdent isEqual:TCSPrefsToolbarItemManager]) {
        [toolbarItem setLabel: @"Manager"];
        [toolbarItem setPaletteLabel: @"Manager"];
        [toolbarItem setToolTip:@"Manager"];
        [toolbarItem setTag:2];
        
        [toolbarItem  setImage:[NSImage imageNamed:@"manager"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(showPane:)];

    } else { 
        toolbarItem = nil;
    }
    
    return toolbarItem;
}


// return an array of the items found in the default toolbar
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar { 
    return [NSArray arrayWithObjects:
        TCSPrefsToolbarItemAppearance, TCSPrefsToolbarItemDefaults
        , TCSPrefsToolbarItemManager,  nil];
}

// return an array of all the items that can be put in the toolbar
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar { 
    return [NSArray arrayWithObjects:
        TCSPrefsToolbarItemAppearance, TCSPrefsToolbarItemDefaults
        , TCSPrefsToolbarItemManager,  nil];
}


// lets us modify items (target, action, tool tip, etc.) as they are added to toolbar
- (void)toolbarWillAddItem:(NSNotification *)notification {
    
}


// handle removal of items.  We have an item that could be a target, so that needs to be reset
- (void)toolbarDidRemoveItem:(NSNotification *)notification { 
    // NSToolbarItem *removedItem = [[notification userInfo] objectForKey: @"item"];
    
}

// works just like menu item validation, but for the toolbar.
- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem { 
    return YES;
}


// allows a selected state
- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
        TCSPrefsToolbarItemAppearance, TCSPrefsToolbarItemDefaults
        , TCSPrefsToolbarItemManager,  nil];
}


// TAB VIEW  ================================================================ //


- (IBAction) showPane:(id)sender {
    logDebug(@"showPane:%@",sender);
    [tabView selectTabViewItemAtIndex:[sender tag]];
    [prefsWindow setTitle:[sender label]];
    [[NSUserDefaults standardUserDefaults] 
        setInteger:[sender tag] 
            forKey:TCSUserDefaultsSelectedPrefPane];
    [self _resizeForIndex:[sender tag]];
}

- (void) _resizeForIndex:(int) idx {
    switch(idx) {
        case 0: 
        {
            NSRect rect = [prefsWindow frame];
//            rect.origin.y = rect.origin.y+(rect.size.height-345);
//            rect.size = NSMakeSize(rect.size.width,345);
            rect.origin.y = rect.origin.y+(rect.size.height-395);
            rect.size = NSMakeSize(rect.size.width,395);
            [prefsWindow setFrame:rect display:YES animate:YES];
            break;
        }
        case 1:
        {
            NSRect rect = [prefsWindow frame];
//            rect.origin.y = rect.origin.y+(rect.size.height-280);
//            rect.size = NSMakeSize(rect.size.width,280);
            rect.origin.y = rect.origin.y+(rect.size.height-330);
            rect.size = NSMakeSize(rect.size.width,330);
            [prefsWindow setFrame:rect display:YES animate:YES];
            break;
        }        
        case 2:
        {
            NSRect rect = [prefsWindow frame];
            rect.origin.y = rect.origin.y+(rect.size.height-285);
            rect.size = NSMakeSize(rect.size.width,285);
            [prefsWindow setFrame:rect display:YES animate:YES];
            break;
        }
        default: break;
    }
    
}


@end
