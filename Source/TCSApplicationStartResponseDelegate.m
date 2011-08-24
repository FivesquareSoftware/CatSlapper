//
//  TCSApplicationStartResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationStartResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSLogger.h"


@implementation TCSApplicationStartResponseDelegate

- (void) handleResponse {
    //parse response
    //OK - Started application at context path /servlets-examples
    logDebug(@"Parsing application start response: %@",rString);
        
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationStartResponseReceived 
                      object:component
                    userInfo:messages];    
}


@end
