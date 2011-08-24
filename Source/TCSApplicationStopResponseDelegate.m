//
//  TCSApplicationStopResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationStopResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSLogger.h"
#import "TCSAppComponent.h"


@implementation TCSApplicationStopResponseDelegate

- (void) handleResponse {
    //parse response
    //OK - Stopped application at context path /servlets-examples
    logDebug(@"Parsing application stop response: %@",rString);
    
    if([[rLines objectAtIndex:0] 
            rangeOfString:@"OK - Stopped application"].location != NSNotFound) {
        [(TCSAppComponent *)component setState:@"0"];
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationStopResponseReceived 
                      object:component
                    userInfo:messages];    
}


@end
