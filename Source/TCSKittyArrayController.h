//
//  TCSKittyArrayController.h
//  TomcatSlapper
//
//  Created by John Clayton on 10/27/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSArrayController+TCSUtils.h"


@interface TCSKittyArrayController : NSArrayController {

}

- (BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem;
- (void) registerObservations;
- (void) removeObservations;

@end
