//
//  TCSApplicationsStatusResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 4/17/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSApplicationsStatusResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import "TCSHostComponent.h"
#import "TCSAppComponent.h"
#import "TCSKitty.h"

@implementation TCSApplicationsStatusResponseDelegate

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing applications status response %@",rString);

    /*
     Name: Catalina:type=Manager,path=/manager,host=local.fivesquare.net
     modelerType: org.apache.catalina.session.StandardManager
     algorithm: MD5
     randomFile: /dev/urandom
     className: org.apache.catalina.session.StandardManager
     debug: 0
     distributable: false
     entropy: org.apache.catalina.session.StandardManager@7fcb8c
     maxActiveSessions: -1
     maxInactiveInterval: 1800
     sessionIdLength: 16
     name: StandardManager
     pathname: SESSIONS.ser
     activeSessions: 0
     sessionCounter: 0
     maxActive: 0
     rejectedSessions: 0
     expiredSessions: 0
     processingTime: 23
     duplicates: 0
     */
    
    TCSKitty *kitty = (TCSKitty *)component;
    NSMutableArray *rHosts = [[NSMutableArray alloc] init];
    TCSHostComponent *host;
    TCSAppComponent *app;
    TCSHostComponent *rHost;
    TCSAppComponent *rApp;
    NSString *hostString;
    NSString *appString;
    if([rString characterAtIndex:0] == 'O') {
        // create hosts and applications from response
        int i;
        for(i = 2; i < [rLines count]; i++) {
            NSString *line = [[rLines objectAtIndex:i] stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *pair = [line componentsSeparatedByString:@": "];
            logTrace(@"pair: %@",pair);
            if([pair count] == 2) {
                NSString *name = [[pair objectAtIndex:0] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *value = [[pair objectAtIndex:1] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                /*
                 Name: Catalina:type=Manager,path=/ModernVictorian,host=localhost
                 maxActiveSessions: -1
                 maxInactiveInterval: 1800
                 activeSessions: 0
                 sessionCounter: 0
                 maxActive: 0
                 rejectedSessions: 0
                 expiredSessions: 0
                 processingTime: 6
                 duplicates: 0
                 */
                if([name isEqualToString:@"Name"]) {
                    NSArray *subValues = [value componentsSeparatedByString:@","];
                    int j;
                    NSString *path;
                    NSString *name;
                    for(j = 0; j < [subValues count]; j++) {
                        NSString *subValue = [subValues objectAtIndex:j];
                        NSArray *subValuePair = [subValue componentsSeparatedByString:@"="];
                        if([subValuePair count] == 2) {
                            NSString *subValueName = [[subValuePair objectAtIndex:0] stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSString *subValueValue = [[subValuePair objectAtIndex:1] stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            if([subValueName isEqualToString:@"path"]) {
                                if([subValueValue length] > 0) {
                                    path = subValueValue; 
                                    logTrace(@"path = %@",path);
                                    if([subValueValue rangeOfString:@"/"].location == 0) {
                                        appString = [subValueValue substringFromIndex:1];
                                        //if([appString isEqualToString:@""]) appString = @"ROOT";
                                    }
                                }
                            } else if ([subValueName isEqualToString:@"host"]) {
                                hostString = subValueValue;
                            }
                        }
                    }
                    /*
                    rApp = [TCSAppComponent withParent:hostString name:appString components:nil];
                    [rApp setPath:path];
                    logTrace(@"rApp: %@",rApp);
                    if([host containsComponent:rApp]) {
                        rApp = (TCSAppComponent *)[host componentWithName:[rApp name]];
                    }
                    //int idx = [[rApp parent] indexOfComponent:rApp];
                    //rApp = (TCSAppComponent *)[[rApp parent] componentAtIndex:idx];
                    logTrace(@"rApp: %@",rApp);
                    logTrace(@"rApp.componentStatus: %@",[rApp componentStatus]);
                    */
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
                    

                } else if([name isEqualToString:@"maxActiveSessions"] && rApp != nil) {
                    [rApp setMaxActiveSessions:value];
                } else if([name isEqualToString:@"maxInactiveInterval"] && rApp != nil) {
                    [rApp setMaxInactiveInterval:value];
                } else if([name isEqualToString:@"activeSessions"] && rApp != nil) {
                    [rApp setActiveSessions:value];
                } else if([name isEqualToString:@"sessionCounter"] && rApp != nil) {
                    [rApp setSessionCounter:value];
                } else if([name isEqualToString:@"maxActive"] && rApp != nil) {
                    [rApp setMaxActive:value];
                } else if([name isEqualToString:@"rejectedSessions"] && rApp != nil) {
                    [rApp setRejectedSessions:value];
                } else if([name isEqualToString:@"expiredSessions"] && rApp != nil) {
                    [rApp setExpiredSessions:value];
                } else if([name isEqualToString:@"processingTime"] && rApp != nil) {
                    [rApp setProcessingTime:value];
                } else if([name isEqualToString:@"duplicates"] && rApp != nil) {
                    [rApp setDuplicates:value];
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
                        [host addComponent:rApp];
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
    
    //TODO remove apps not here
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationApplicationsStatusUpdateReceived 
                      object:kitty
                    userInfo:messages];    
}



@end
