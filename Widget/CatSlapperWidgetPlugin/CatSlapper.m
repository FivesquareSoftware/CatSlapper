//
//  CatSlapper.m
//  CatSlapperWidgetPlugin
//
//  Created by John Clayton on 11/3/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "CatSlapper.h"


static NSString *scriptFormat = 
                    @"tell application \"CatSlapper\"\n \
                        %@\n \
                    end tell";

static NSString *statusTextOfSelectedKittySource = 
                    @"status text of selected kitty";
static NSString *nameOfSelectedKittySource = 
                    @"name of selected kitty";
static NSString *isRunningOfSelectedKittySource = 
                    @"is running of selected kitty";
static NSString *toggleSelectedKittySource = 
                    @"toggle selection";
static NSString *restartSelectedKittySource = 
                    @"restart selection";

@implementation CatSlapper

// WIDGET PLUGIN INTERFACE ================================================== //

- (id) initWithWebView:(WebView *)aWebView {
    if(self = [super init]) {
        webView = [aWebView retain];
        statusTextOfSelectedKittyScript = 
            [self _scriptWithSource:statusTextOfSelectedKittySource];
        nameOfSelectedKittyScript = 
            [self _scriptWithSource:nameOfSelectedKittySource];
        isRunningOfSelectedKittyScript = 
            [self _scriptWithSource:isRunningOfSelectedKittySource];
        toggleSelectedKittyScript = 
            [self _scriptWithSource:toggleSelectedKittySource];
        restartSelectedKittyScript = 
            [self _scriptWithSource:restartSelectedKittySource];
    }
    return self;
}

- (NSAppleScript *) _scriptWithSource:(NSString *)scriptSource {
    return [[NSAppleScript alloc] initWithSource:
        [NSString stringWithFormat:scriptFormat,scriptSource]];
}

- (void) dealloc {
    [webView release];
    [statusTextOfSelectedKittyScript release];
    [nameOfSelectedKittyScript release];
    [isRunningOfSelectedKittyScript release];
    [toggleSelectedKittyScript release];
    [restartSelectedKittyScript release];
    [super dealloc];
}

- (void) windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
    //NSLog(@"windowScriptObjectAvailable");
    [windowScriptObject setValue:self forKey:@"CatSlapper"];
}


// webScriptNameForSelector
//
// This method lets you offer friendly names for methods that normally 
// get mangled when bridged into JavaScript.
+ (NSString *) webScriptNameForSelector:(SEL)aSel {
    NSString *retval = nil;
    
    //NSLog(@"webScriptNameForSelector");
    if (aSel == @selector(isOpen)) {
        retval = @"isOpen";
    } else if (aSel == @selector(selectedKittyStatusText)) {
        retval = @"selectedKittyStatusText";
    } else if (aSel == @selector(selectedKittyName)) {
        retval = @"selectedKittyName";
    } else if (aSel == @selector(selectedKittyIsRunning)) {
        retval = @"selectedKittyIsRunning";
    } else if (aSel == @selector(toggleSelectedKitty)) {
        retval = @"toggleSelectedKitty";
    } else if (aSel == @selector(restartSelectedKitty)) {
        retval = @"restartSelectedKitty";
    } else if (aSel == @selector(logMessage:)) {
        retval = @"logMessage";
    } else {
        NSLog(@"\tunknown selector");
    }
    
    return retval;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)aSel {	
    if (aSel == @selector(isOpen)
        || aSel == @selector(selectedKittyStatusText) 
        || aSel == @selector(selectedKittyName)
        || aSel == @selector(selectedKittyIsRunning)
        || aSel == @selector(toggleSelectedKitty)
        || aSel == @selector(restartSelectedKitty)
        || aSel == @selector(logMessage:)) {
        return NO;
    }
    return YES;
}

+ (BOOL) isKeyExcludedFromWebScript:(const char*)k {
    return YES;
}


// JAVASCRIPT EXPOSED METHODS =============================================== //

- (BOOL) isOpen {
    //NSLog(@"isOpen");
    BOOL open = NO;
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    unsigned int i, count = [apps count];
    for (i = 0; i < count; i++) {
        NSString *appName = [(NSDictionary *)[apps objectAtIndex:i] 
            objectForKey:@"NSApplicationName"];
        if([appName isEqualToString:@"CatSlapper"]) {
            open = YES;
            break;
        }
    }
    return open;
}

- (NSString *) selectedKittyStatusText {
    //NSLog(@"selectedKittyStatusText");
    NSDictionary *errorInfo = [NSDictionary dictionary];
    id result = 
        [statusTextOfSelectedKittyScript executeAndReturnError:&errorInfo];
    if(result == nil) {
        [self logMessage:[NSString stringWithFormat:
            @"%@",errorInfo]];
    }
    [self logMessage:[NSString stringWithFormat:
                        @"result.stringValue = %@"
                        ,[result stringValue]]];
    return[result stringValue];
}

- (NSString *) selectedKittyName {
    //NSLog(@"selectedKittyName");
    NSDictionary *errorInfo = [NSDictionary dictionary];
    id result = 
        [nameOfSelectedKittyScript executeAndReturnError:&errorInfo];
    if(result == nil) {
        [self logMessage:[NSString stringWithFormat:
            @"%@",errorInfo]];
    }
    [self logMessage:[NSString stringWithFormat:
        @"result.stringValue = %@"
        ,[result stringValue]]];
    return[result stringValue];
}

- (BOOL) selectedKittyIsRunning {
    NSDictionary *errorInfo = [NSDictionary dictionary];
    id result = 
        [isRunningOfSelectedKittyScript executeAndReturnError:&errorInfo];
    if(result == nil) {
        [self logMessage:[NSString stringWithFormat:
            @"%@",errorInfo]];
    }
    [self logMessage:[NSString stringWithFormat:
        @"result.stringValue = %@"
        ,[result stringValue]]];
    return [[result stringValue] isEqualToString:@"true"];
}

- (void) toggleSelectedKitty {
    NSDictionary *errorInfo = [NSDictionary dictionary];
    id result = 
        [toggleSelectedKittyScript executeAndReturnError:&errorInfo];
    if(result == nil) {
        [self logMessage:[NSString stringWithFormat:
            @"%@",errorInfo]];
    }
    [self logMessage:[NSString stringWithFormat:
        @"result.stringValue = %@"
        ,[result stringValue]]];
}

- (void) restartSelectedKitty {
    NSDictionary *errorInfo = [NSDictionary dictionary];
    id result = 
        [restartSelectedKittyScript executeAndReturnError:&errorInfo];
    if(result == nil) {
        [self logMessage:[NSString stringWithFormat:
            @"%@",errorInfo]];
    }
    [self logMessage:[NSString stringWithFormat:
        @"result.stringValue = %@"
        ,[result stringValue]]];
}

// Sends the message passed in from JavaScript to the console.
- (void) logMessage:(NSString *)str {
#ifdef DEBUG
    NSLog(@"[CatSlapper.widgetplugin] %@", str);
#endif
}


@end
