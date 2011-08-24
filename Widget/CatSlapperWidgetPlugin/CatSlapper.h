//
//  CatSlapper.h
//  CatSlapperWidgetPlugin
//
//  Created by John Clayton on 11/3/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface CatSlapper : NSObject {
    WebView *webView;
    NSAppleScript *statusTextOfSelectedKittyScript;
    NSAppleScript *nameOfSelectedKittyScript;
    NSAppleScript *isRunningOfSelectedKittyScript;
    NSAppleScript *toggleSelectedKittyScript;
    NSAppleScript *restartSelectedKittyScript;
}

- (NSAppleScript *) _scriptWithSource:(NSString *)scriptSource;
- (void) logMessage:(NSString *)str;

@end
