//
//  TCSServerErrorDisplayController.m
//  TomcatSlapper
//
//  Created by John Clayton on 12/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSServerErrorDisplayController.h"
#import "TCSConstants.h"


@implementation TCSServerErrorDisplayController

static TCSServerErrorDisplayController *controller;


- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super initWithWindowNibName:@"ServerErrors"]) {
        
    }
    return self;
}
    

// SINGLETON PREF CONTROLLER ================================================ //

+ (TCSServerErrorDisplayController *) displayController {
    if(controller == nil) {
        controller = [[TCSServerErrorDisplayController alloc] _init];
        [controller window]; //loads nib
    }
    return controller;
}

- (NSArrayController *) errorArrayController {
    return errorArrayController;
}



// WINDOW CONTROLLER ======================================================== //

- (void) showWindow:(id)sender {
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)aNotification { 
    //TODO do I need to save to user defaults here?
}

- (void) windowDidLoad {
    [[self window] setFrameAutosaveName:TCSErrorWindowSaveName];
}

@end
