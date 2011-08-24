//
//  TCSComponentViewDataSource.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/25/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCSCatSlapper;
@class TCSTomcatManagerProxy;
@class TCSComponentNameCell;

@interface TCSComponentViewDataSource : NSObject {
    IBOutlet NSArrayController *kittyController;
    IBOutlet TCSCatSlapper *catSlapper;
    IBOutlet NSOutlineView *componentView;
    IBOutlet NSPanel *infoPanel;
    IBOutlet NSTextField *selectedItemNameField;
    IBOutlet NSTextField *selectedItemInfoField;
    IBOutlet TCSTomcatManagerProxy *managerProxy;
    IBOutlet NSProgressIndicator *componentUpdateProgressIndicator;
    IBOutlet NSButton *componentUpdateButton;
    IBOutlet NSTextField *componentUpdateStatusField;
        
    NSPopUpButtonCell *serverCommandCell;
    NSPopUpButtonCell *hostsCommandCell;
    NSPopUpButtonCell *appCommandCell;
    NSTextFieldCell *textCell;
    
}

- (IBAction) displayItemInfo:(id)sender;
- (IBAction) displayItemStatus:(id) sender;
- (IBAction) closeInfoPanel:(id)sender;


- (id) dataCellForItem:(id)item tableColumn:(NSTableColumn *)tableColumn;
- (void) startProgressAnimation;
- (void) stopProgressAnimation;
- (void) postMessage:(NSString *) msg;
- (void) postFormat:(NSString *) format, ... ;

- (void) registerObservations;
- (void) removeObservations;

@end
