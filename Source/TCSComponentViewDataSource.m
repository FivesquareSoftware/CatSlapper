//
//  TCSComponentViewDataSource.m
//  TomcatSlapper
//
//  Created by John Clayton on 12/25/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSComponentViewDataSource.h"
#import "TCSComponentViewDataSource+Private.h"
#import "TCSLogger.h"
#import "TCSCatSlapper.h"
#import "TCSComponentNameCell.h"
#import "TCSComponent.h"
#import "TCSKitty.h"
#import "TCSConnectorComponent.h"
#import "TCSHostComponent.h"
#import "TCSAppComponent.h"
#import "TCSTomcatManagerProxy.h"
#import "TCSTomcatManagerDeployController.h"
#import "TCSKittyArrayController.h"

@implementation TCSComponentViewDataSource

// OBJECT STUFF ============================================================= //

- (void) awakeFromNib {
    [self registerObservations];
    [self _initCommandCells];

    [componentView reloadData];
}


- (void) dealloc {
    [serverCommandCell release];
    [hostsCommandCell release];
    [appCommandCell release];
    [textCell release];
    
    [self removeObservations];
    [super dealloc];
}


// IBACTIONS ================================================================ //
#pragma mark Interface methods

- (IBAction) displayItemInfo:(id)sender {
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logTrace(@"selectedItem: %@",item);
    logTrace(@"selectedItem.name: %@",[item name]);
    logTrace(@"selectedItem.componentInfo: %@",[item componentInfo]);
    [selectedItemNameField setStringValue:[item name]];
    [selectedItemInfoField setStringValue:[item componentInfo]];
    [infoPanel setTitle:[item name]];
    [infoPanel makeKeyAndOrderFront:self];
}


- (IBAction) displayItemStatus:(id) sender {
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logTrace(@"selectedItem: %@",item);
    logTrace(@"selectedItem.name: %@",[item name]);
    logTrace(@"selectedItem.componentStatus: %@",[item componentStatus]);
    [selectedItemNameField setStringValue:[item name]];
    [selectedItemInfoField setStringValue:[item componentStatus]];
    [infoPanel setTitle:[item name]];
    [infoPanel makeKeyAndOrderFront:self];
}

- (IBAction) closeInfoPanel:(id)sender {
    [infoPanel orderOut:self];
}

- (IBAction) startWebapp:(id) sender {
    logDebug(@"startWebapp:%@",sender);
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logDebug(@"item = %@",item);
    TCSKitty *tk = [catSlapper selectedKitty];
    [managerProxy startApplication:(TCSAppComponent *)item
                                   forKitty:tk];
}

- (IBAction) stopWebapp:(id) sender {
    logDebug(@"stopWebapp:%@",sender);
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logDebug(@"item = %@",item);
    TCSKitty *tk = [catSlapper selectedKitty];
    [managerProxy stopApplication:(TCSAppComponent *)item 
                                   forKitty:tk];
}

- (IBAction) reloadWebapp:(id) sender {
    logDebug(@"reloadWebapp:%@",sender);
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logDebug(@"item = %@",item);
    TCSKitty *tk = [catSlapper selectedKitty];
    [managerProxy reloadApplication:(TCSAppComponent *)item 
                                   forKitty:tk];
}

- (IBAction) deployWebapp:(id) sender {
    logDebug(@"deployWebapp:%@",sender);
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logDebug(@"item = %@",item);
    TCSKitty *tk = [catSlapper selectedKitty];
    TCSHostComponent *host = (TCSHostComponent *)item;
    NSURLRequest *request = 
        [[TCSTomcatManagerDeployController sharedDeployController] 
            deploymentRequestToHost:host];
    logDebug(@"request = %@",request);
    if(request != nil) {
        [managerProxy deploymentRequest:request 
                                 onHost:host
                               forKitty:tk];
    }
}

- (IBAction) undeployWebapp:(id) sender {
    logDebug(@"undeployWebapp:%@",sender);
    id item = [componentView itemAtRow:[componentView selectedRow]];
    logDebug(@"item = %@",item);
    [managerProxy undeployApplication:(TCSAppComponent *)item];
}

- (void) startProgressAnimation {
    [componentUpdateButton setImage:[NSImage imageNamed:@"cancel_w"]];
    [componentUpdateButton setAlternateImage:[NSImage imageNamed:@"cancel_b"]];
    [componentUpdateButton setAction:@selector(cancelCurrentRequest:)];
    [componentUpdateButton setTarget:managerProxy];
    [componentUpdateProgressIndicator startAnimation:self];
}

- (void) stopProgressAnimation {
    [componentUpdateButton setAction:@selector(updateComponentsForSelectedKitty:)];
    [componentUpdateButton setTarget:catSlapper];
    [componentUpdateButton setImage:[NSImage imageNamed:@"redo_w"]];
    [componentUpdateButton setAlternateImage:[NSImage imageNamed:@"redo_b"]];
    [componentUpdateProgressIndicator stopAnimation:self];
//    [componentUpdateStatusField setStringValue:@""];
}

- (void) postMessage:(NSString *) msg {
    [componentUpdateStatusField setStringValue:msg];
}

- (void) postFormat:(NSString *) format, ... {
    va_list args;
    va_start(args,format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);        
    
    [componentUpdateStatusField setStringValue:msg];
}


// OUTLINE VIEW DATA SOURCE ================================================= //
#pragma mark Data Source Methods

//special method to allow different data cells
// see our column subclass
- (id) dataCellForItem:(id)item tableColumn:(NSTableColumn *)tableColumn {
    //logDebug(@"item.class = %@",[item class]);
    //logDebug(@"item.name = %@",[item name]);
    logTrace(@"tableColumn.identifier = %@",[tableColumn identifier]);
    id cell = nil;
    logTrace(@"dataCellForItem:%@",item);
    id identifier = [tableColumn identifier];
    /*
    if([identifier isEqual:@"statusText"]) {
        if([item isKindOfClass:[TCSKitty class]]
           || [item isKindOfClass:[TCSConnectorComponent class]]
           || [item isKindOfClass:[TCSHostComponent class]]
           || [item isKindOfClass:[TCSAppComponent class]]) {
            cell = buttonCell;
        } else {
            cell = textCell;
        }
        
    } else
        */
    if([identifier isEqual:@"command"]) {
        if([item isKindOfClass:[TCSKitty class]]) {
            logTrace(@"setting cell to %@",serverCommandCell);            
            cell  = serverCommandCell;
        } else if([item isKindOfClass:[TCSHostComponent class]]) {
            logTrace(@"setting cell to %@",hostsCommandCell);            
            cell = hostsCommandCell;
        } else if([item isKindOfClass:[TCSAppComponent class]]) {
            logTrace(@"setting cell to %@",appCommandCell);            
            cell = appCommandCell;
        } else {
            logTrace(@"setting cell to %@",textCell);            
            cell = textCell;
        }
    } 
    return cell;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    logDebug(@"numberOfChildrenOfItem:%@",item);
    int count = 0;
    if(item != nil) {
        NSArray *components = [item valueForKey:@"components"];
        count = [components count];
    } else if ([catSlapper selectedKitty] != nil) {
        count = 1;
    }
    return count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    logDebug(@"isItemExpandable:%@",item);
    BOOL isExpandable = NO;
    if(item != nil) {
        NSArray *components = [item valueForKey:@"components"];
        isExpandable = ([components count] > 0);
    }
    return isExpandable;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
    id child = nil;
    if([kittyController selectionIndex] != NSNotFound) 
        child = [catSlapper objectInKittensAtIndex:[kittyController selectionIndex]];
    if(item != nil) {
        NSArray *components = [item valueForKey:@"components"];
        logTrace(@"item = %@",item);
        logTrace(@"item.components = %@",components);
        child = [components objectAtIndex:index];
    }
    return child;
}

- (id)outlineView:(NSOutlineView *)outlineView 
        objectValueForTableColumn:(NSTableColumn *)tableColumn 
                           byItem:(id)item {
    logTrace(@"item = %@",item);
    id objValue = [item valueForKey:[tableColumn identifier]];
    //logDebug(@"objectValueForTableColumn:%@ = %@",[tableColumn identifier],objValue);
    return objValue;
}

- (void)outlineView:(NSOutlineView *)outlineView 
     setObjectValue:(id)object 
     forTableColumn:(NSTableColumn *)tableColumn 
             byItem:(id)item {
    if([[tableColumn identifier] isEqual:@"command"]) {
        logTrace(@"%@ setValue:%@ forKey:%@",item, object,[tableColumn identifier]);
        [item setValue:object forKey:[tableColumn identifier]];
    }
}


// NSOutlineView DELEGATE METHODS =========================================== //

- (void)outlineView:(NSOutlineView *)olv 
    willDisplayCell:(NSCell *)cell 
     forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if([[tableColumn identifier] isEqualToString:@"name"]) {
        logTrace(@"item.class = %@",[item class]);
        [cell setImage:[item icon]];
        [cell setTitle:[item name]];
    }
    if([[tableColumn identifier] isEqual:@"statusText"]) {
        logTrace(@"item.statusText = %@",[item statusText]);
        [cell setTitle:[item statusText]];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification {
}

// COMMAND MENU DELEGATE ==================================================== //

#pragma mark command menu delegate

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
    logTrace(@"validateMenuItem:%@",menuItem);
    TCSKitty *tk = [catSlapper selectedKitty];
    return ([tk isRunning] ? YES : NO);
}




// OBSERVATIONS ============================================================= //

#pragma mark Observations

- (void) registerObservations {

    /*   TCSCatSlapper now watches selection change for me
    [kittyController addObserver:self
                      forKeyPath:@"selection" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    */
    [kittyController addObserver:self
                      forKeyPath:@"selection.isRunning" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
}

- (void) removeObservations {
  //  [kittyController removeObserver:self forKeyPath:@"selection"];    
    [kittyController removeObserver:self forKeyPath:@"selection.isRunning"];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    logDebug(@"TCSComponentViewDataSource observed %@",keyPath);
    /*
    if([keyPath isEqualToString:@"selection"]) {
        [componentView reloadData];
    }
    */
    BOOL isRunning = [kittyController safeBoolValueForKeyPath:keyPath];
    logDebug(@"kitty run state changed to %d",isRunning);
    [componentView reloadData];
}


// CUSTOM DATA CELLS ======================================================== //

- (void) _initCommandCells {
    // for no commands
    //BACTRACK removed extra retain
    textCell = [[NSTextFieldCell alloc] init];
    [textCell setFont:[NSFont fontWithName:@"Lucida Grande" size:10.0]];
    
    //BACTRACK removed extra retains
    //set up command cells
    serverCommandCell = [[NSPopUpButtonCell alloc] init];
    hostsCommandCell = [[NSPopUpButtonCell alloc] init];
    appCommandCell = [[NSPopUpButtonCell alloc] init];    

    [serverCommandCell setControlSize:NSSmallControlSize];
    [serverCommandCell setBordered:NO];
    [serverCommandCell setFont:[NSFont systemFontOfSize:10.0]];

    [hostsCommandCell setControlSize:NSSmallControlSize];
    [hostsCommandCell setBordered:NO];
    [hostsCommandCell setFont:[NSFont systemFontOfSize:10.0]];
    
    [appCommandCell setControlSize:NSSmallControlSize];
    [appCommandCell setBordered:NO];
    [appCommandCell setFont:[NSFont systemFontOfSize:10.0]];
    
    // set up menus
    //BACTRACK removed extra retains
    NSMenu *serverMenu = [[NSMenu alloc] init];
    NSMenu *hostMenu =[[NSMenu alloc] init];
    NSMenu *applicationMenu = [[NSMenu alloc] init];
    
    [serverMenu setDelegate:self];
    [hostMenu setDelegate:self];
    [applicationMenu setDelegate:self];

    
    //server menu    
    NSMenuItem *serverToggleItem = [[NSMenuItem alloc] init];
    [serverToggleItem setTitle:@"Toggle"];
    [serverToggleItem setTarget:catSlapper];
    [serverToggleItem setAction:@selector(toggleKitty:)];
    [serverMenu addItem:serverToggleItem];
    
    [serverCommandCell setMenu:serverMenu];
    
    //hosts menu
    NSMenuItem *hostsDeployItem = [[NSMenuItem alloc] init];
    [hostsDeployItem setTitle:@"Deploy webapp"];
    [hostsDeployItem setTarget:self];
    [hostsDeployItem setAction:@selector(deployWebapp:)];
    [hostMenu addItem:hostsDeployItem];
    
    [hostsCommandCell setMenu:hostMenu];

    //app menu
    NSMenuItem *appStartItem = [[NSMenuItem alloc] init];
    [appStartItem setTitle:@"Start webapp"];
    [appStartItem setTarget:self];
    [appStartItem setAction:@selector(startWebapp:)];
    [applicationMenu addItem:appStartItem];

    NSMenuItem *appStopItem = [[NSMenuItem alloc] init];
    [appStopItem setTitle:@"Stop webapp"];
    [appStopItem setTarget:self];
    [appStopItem setAction:@selector(stopWebapp:)];
    [applicationMenu addItem:appStopItem];

    NSMenuItem *appReloadItem = [[NSMenuItem alloc] init];
    [appReloadItem setTitle:@"Reload webapp"];
    [appReloadItem setTarget:self];
    [appReloadItem setAction:@selector(reloadWebapp:)];
    [applicationMenu addItem:appReloadItem];

    NSMenuItem *appUndeployItem = [[NSMenuItem alloc] init];
    [appUndeployItem setTitle:@"Undeploy webapp"];
    [appUndeployItem setTarget:self];
    [appUndeployItem setAction:@selector(undeployWebapp:)];
    [applicationMenu addItem:appUndeployItem];
    [appCommandCell setMenu:applicationMenu];    
    
}


@end
