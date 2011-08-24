//
//  TCSNoPopupSelectionTransformer.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/24/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Why? Because an NSArrayController can return NSNotFound from selectionIndex
//    which can try to set that value as the selection of the popUp
#define TCS_NO_SELECTION NSNotFound

@interface TCSNoPopupSelectionTransformer : NSValueTransformer {

}

@end
