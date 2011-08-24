//
//  TCSApplicationsInfoResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationsInfoResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import "TCSHostComponent.h"
#import "TCSAppComponent.h"
#import "TCSKitty.h"


@implementation TCSApplicationsInfoResponseDelegate

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing applications info response %@",rString);

    TCSKitty *kitty = (TCSKitty *)component;
    NSMutableArray *rHosts = [[NSMutableArray alloc] init];
    TCSHostComponent *host;
    TCSAppComponent *app;
    TCSHostComponent *rHost;
    TCSAppComponent *rApp;
    if([rString characterAtIndex:0] == 'O') {
        // create hosts and applications from response
        int i;
        for(i = 2; i < [rLines count]; i++) {
            NSString *line = [[rLines objectAtIndex:i] stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *pair = [line componentsSeparatedByString:@": "];
            logTrace(@"pair: %@",pair);
            logTrace(@"pair.count = %d",[pair count]);
            if([pair count] == 2) {
//                NSRange pairRange = [line rangeOfString:@": "];
//                NSString *name = [line substringToIndex:pairRange.location];
                NSString *name = [[pair objectAtIndex:0] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                logTrace(@"name='%@'",name);
//                NSString *value = [line substringFromIndex:pairRange.location+2];
                NSString *value = [[pair objectAtIndex:1] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                /*
                 Name: Catalina:j2eeType=WebModule,name=//localhost/ModernVictorian,J2EEApplication=none,J2EEServer=none
                 docBase: /usr/local/tomcat/webapps/ModernVictorian
                 path: /ModernVictorian
                 startupTime: 112
                 state: 1
                 workDir: work/Catalina/localhost/ModernVictorian
                 */
                if([name isEqualToString:@"Name"]) {
                    NSArray *subValues = [value componentsSeparatedByString:@","];
                    int j;
                    for(j = 0; j < [subValues count]; j++) {
                        NSString *subValue = [subValues objectAtIndex:j];
                        NSArray *subValuePair = [subValue componentsSeparatedByString:@"="];
                        if([subValuePair count] == 2) {
                            NSString *subValueName = [[subValuePair objectAtIndex:0] stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSString *subValueValue = [[subValuePair objectAtIndex:1] stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            if([subValueName isEqualToString:@"name"]) {
                                NSString *hostString;
                                NSString *appString;
                                logTrace(@"splitting %@",subValueValue);
                                //localhost/ModernVictorian
                                NSString *tmpString = [subValueValue substringFromIndex:2];
                                NSRange slashRange = [tmpString rangeOfString:@"/"];
                                logTrace(@"slashRange.location: %d",slashRange.location);
                                hostString = [tmpString substringToIndex:slashRange.location];
                                appString = [tmpString substringFromIndex:slashRange.location+1];
                                logTrace(@"//%@/%@",hostString,appString);
                                
                                if(hostString != nil && appString != nil) {
                                    //if([appString isEqualToString:@""]) appString = @"ROOT";
                                    rHost = 
                                    [TCSHostComponent 
                                            withParent:kitty 
                                                  name:hostString
                                            components:nil];
                                    if(![rHosts containsObject:rHost]) {
                                        [rHosts addObject:rHost]; 
                                    } else {
                                        int idx =[rHosts indexOfObject:rHost];
                                        rHost = [rHosts objectAtIndex:idx];
                                    }
                                    rApp = 
                                        [TCSAppComponent 
                                            withParent:rHost 
                                                  name:appString 
                                            components:nil];
                                    [rHost addComponent:rApp];
                                    logTrace(@"rHost: %@",rHost);
                                    logTrace(@"rApp: %@",rApp);
                                }
                            }
                        }
                    }
                   
//                } else if([name isEqualToString:@"deploymentDescriptor"] && rApp != nil) {
//                    logDebug(@"rApp.setDeploymentDescriptor:");
//                    [rApp setDeploymentDescriptor:value];
                } else if([name isEqualToString:@"docBase"] && rApp != nil) {
                    [rApp setDocBase:value];
//                } else if([name isEqualToString:@"path"] && rApp != nil) {
//                    [rApp setPath:(value == nil || [value isEqualToString:@""] ? @"/" : value)];
                } else if([name isEqualToString:@"startupTime"] && rApp != nil) {
                    [rApp setStartupTime:value];
                } else if([name isEqualToString:@"state"] && rApp != nil) {
                    [rApp setState:value];
                } else if([name isEqualToString:@"workDir"] && rApp != nil) {
                    [rApp setWorkDir:value];
                    rApp = nil;
                } 
            }
        }
        
        // loop through hosts comparing apps to known hosts
        int k;
        for(k = 0; k < [rHosts count]; k++) {
            logTrace(@"kitty = %@",kitty);
            rHost = (TCSHostComponent *)[rHosts objectAtIndex:k];
            host = (TCSHostComponent *)[kitty componentWithName:[rHost name]];
            logTrace(@"rHost = %@",rHost);
            logTrace(@"host = %@",host);
            logTrace(@"rHost.components = %@",[rHost components]);
            logTrace(@"host.components = %@",[host components]);
            if(host != nil) {
                int m;
                for(m = 0; m < [rHost numberOfComponents];m++) {
                    rApp = (TCSAppComponent *)[rHost componentAtIndex:m];
                    // only add app if it's deployed
                    if(![host containsComponent:rApp]){
                        logTrace(@"%@.addComponent:%@",host,rApp);
                        //logTrace(@"deploymentDescriptor = %@",[rApp deploymentDescriptor]);
//                        if ( [rApp deploymentDescriptor] != nil 
//                            && ![[rApp deploymentDescriptor] isEqualToString:@""] ) {
                        logTrace(@"rApp.parent = %@",[rApp parent]);
                        [host addComponent:rApp];
                        logTrace(@"rApp.parent = %@",[rApp parent]);
//                        }
                    } else {
                        logTrace(@"%@.updateComponent:%@",host,rApp);
                        int idx = [host indexOfComponent:rApp];
                        [[host componentAtIndex:idx] updateWithComponent:rApp];
                    }
                }
                logTrace(@"host.numberOfComponents: %d",[host numberOfComponents]);
                int n;
                for(n = 0; n < [host numberOfComponents];n++) {
                    app = (TCSAppComponent *)[host componentAtIndex:n];
                    if(![rHost containsComponent:app]) {
                        logTrace(@"%@.removeComponent:%@",host,app);
                        [host removeComponent:app];
                    }
                }
            }
        }
        logTrace(@"host.components = %@",[host components]);
    } else {
        logError(@"Manager encountered an error");
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationsInfoUpdateReceived 
                      object:kitty
                    userInfo:messages];    
}


@end
