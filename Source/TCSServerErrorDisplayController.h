//
//  TCSServerErrorDisplayController.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSArrayController;

@interface TCSServerErrorDisplayController : NSWindowController {
    IBOutlet NSArrayController *errorArrayController;
}

+ (TCSServerErrorDisplayController *) displayController;
- (NSArrayController *) errorArrayController;


@end
