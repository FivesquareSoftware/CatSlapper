//
//  TCSPrefsToolbarDelegate.h
//  TomcatSlapper
//
//  Created by John Clayton on 4/25/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSPrefsToolbarDelegate : NSObject {
    NSToolbar *toolbar;

    IBOutlet NSTabView *tabView;
    IBOutlet NSWindow *prefsWindow;
}

- (IBAction) showPane:(id)sender;
- (void) _resizeForIndex:(int) idx;

@end
