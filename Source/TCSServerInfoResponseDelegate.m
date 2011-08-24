//
//  TCSServerInfoResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSServerInfoResponseDelegate.h"
#import "TCSLogger.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSKitty.h"

@implementation TCSServerInfoResponseDelegate

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing server info response %@",rString);
    /*
     OK - Server info
     Tomcat Version: Apache Tomcat/5.0.28
     OS Name: Mac OS X
     OS Version: 10.3.8
     OS Architecture: ppc
     JVM Version: 1.4.2_05-141.4
     JVM Vendor: "Apple Computer, Inc."
     */
    TCSKitty *kitty = (TCSKitty *)component;
    if([rString characterAtIndex:0] == 'O') {
        // create connectors from response
        int i;
        for(i = 0; i < [rLines count]; i++) {
            NSString *line = [[rLines objectAtIndex:i] stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *pair = [line componentsSeparatedByString:@": "];
            logTrace(@"pair: %@",pair);
            if([pair count] == 2) {
                NSString *name = [[pair objectAtIndex:0] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *value = [[pair objectAtIndex:1] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if([name isEqualToString:@"Tomcat Version"]) {
                    [kitty setVersion:value];
                } else if([name isEqualToString:@"OS Name"]) {
                    [kitty setOsName:value];
                } else if([name isEqualToString:@"OS Version"]) {
                    [kitty setOsVersion:value];
                } else if([name isEqualToString:@"OS Architecture"]) {
                    [kitty setOsArch:value];
                } else if([name isEqualToString:@"JVM Version"]) {
                    [kitty setJvmVersion:value];
                } else if([name isEqualToString:@"JVM Vendor"]) {
                    [kitty setJvmVendor:value];
                } 
            }
        }
    } else {
        logError(@"Manager encountered an error");
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationServerInfoUpdateReceived 
                      object:kitty
                    userInfo:messages];    
    
}


@end
