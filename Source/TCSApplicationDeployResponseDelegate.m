//
//  TCSApplicationDeployResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationDeployResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSLogger.h"
#import "TCSAppComponent.h"

@implementation TCSApplicationDeployResponseDelegate

- (void) handleResponse {
    //parse response
    logDebug(@"Parsing application deploy response: %@",rString);

    //OK - Undeployed application at context path /webdav
    //OK - Deployed application at context path /TestWebService2
    NSString *firstLine = [rLines objectAtIndex:0];
    NSRange deployedRange = 
        [firstLine rangeOfString:@"OK - Deployed application at context path "];
    if(deployedRange.location != NSNotFound) {
        NSString *path = [firstLine 
            substringFromIndex:(deployedRange.location+deployedRange.length)];
        NSString *name;
        if([path rangeOfString:@"/"].location == 0) {
            name = [[path substringFromIndex:1] 
                        stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        logDebug(@"name = %@",name);
        TCSAppComponent *app = [TCSAppComponent withParent:component name:name components:nil];
        logDebug(@"app = %@",app);
        logDebug(@"component = %@",component);
        logDebug(@"component.componenets = %@",[component components]);
        [component addComponent:app];
        logDebug(@"component.componenets = %@",[component components]);
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationDeployResponseReceived 
                      object:component
                    userInfo:messages];    
}

@end
