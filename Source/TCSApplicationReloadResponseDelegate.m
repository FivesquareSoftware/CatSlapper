//
//  TCSApplicationReloadResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationReloadResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSLogger.h"


@implementation TCSApplicationReloadResponseDelegate

- (void) handleResponse {
    //parse response
    //start response OK - Reloaded application at context path /servlets-examples
    logDebug(@"Parsing application reload response: %@",rString);

    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationReloadResponseReceived 
                      object:component
                    userInfo:messages];    
}


@end
