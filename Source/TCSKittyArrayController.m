//
//  TCSKittyArrayController.m
//  TomcatSlapper
//
//  Created by John Clayton on 10/27/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSKittyArrayController.h"
#import "TCSConstants.h"
#import "TCSLogger.h"

@implementation TCSKittyArrayController

- (void) awakeFromNib {
    [self registerObservations];
}

- (void) dealloc {
    [self removeObservations];
    [super dealloc];
}



// OBSERVATIONS ============================================================= //
#pragma mark Observations

- (void) registerObservations {
}

- (void) removeObservations {
}


@end
