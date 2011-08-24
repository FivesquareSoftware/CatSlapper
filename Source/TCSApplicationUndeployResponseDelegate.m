//
//  TCSApplicationUndeployResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationUndeployResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSLogger.h"
#import "TCSAppComponent.h"


@implementation TCSApplicationUndeployResponseDelegate

- (void) handleResponse {
    //parse response
    logDebug(@"Parsing application undeploy response: %@",rString);
    //OK - Undeployed application at context path /webdav
    if([[rLines objectAtIndex:0] 
            rangeOfString:@"OK - Undeployed application"].location != NSNotFound) {
        logDebug(@"component = %@",component);
        logDebug(@"component.parent = %@",[component parent]);
        logDebug(@"component.parent.components = %@",[[component parent] components]);
        [[component parent] removeComponent:component];
        logDebug(@"component.parent.components = %@",[[component parent] components]);
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationUndeployResponseReceived 
                      object:component
                    userInfo:messages];    
}

@end
