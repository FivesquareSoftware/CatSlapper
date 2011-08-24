//
//  TCSHostsInfoResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSHostsInfoResponseDelegate.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import "TCSHostComponent.h"
#import "TCSKitty.h"



@implementation TCSHostsInfoResponseDelegate

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing hosts response %@",rString);

    /*
    OK - Number of results: 2

    Name: Catalina:type=Host,host=local.fivesquare.net
    modelerType: org.apache.catalina.core.StandardHost
    appBase: /Users/johnclay/Sites/fivesquaresoftware.com
    autoDeploy: true
    debug: 0
    deployOnStartup: true
    deployXML: true
    managedResource: StandardEngine[Catalina].StandardHost[local.fivesquare.net]
    name: local.fivesquare.net
    unpackWARs: true
    xmlNamespaceAware: false
    xmlValidation: false
    children: [Ljavax.management.ObjectName;@68f17d
    aliases: [Ljava.lang.String;@77d2c2
    realm: org.apache.catalina.realm.UserDatabaseRealm@add1c5
    valveNames: [Ljava.lang.String;@c64ae1
    valveObjectNames: [Ljavax.management.ObjectName;@5e331b

    Name: Catalina:type=Host,host=localhost
    modelerType: org.apache.catalina.core.StandardHost
    appBase: webapps
    autoDeploy: true
    debug: 0
    deployOnStartup: true
    deployXML: true
    managedResource: StandardEngine[Catalina].StandardHost[localhost]
    name: localhost
    unpackWARs: true
    xmlNamespaceAware: false
    xmlValidation: false
    children: [Ljavax.management.ObjectName;@c26564
    aliases: [Ljava.lang.String;@99ea11
    realm: org.apache.catalina.realm.UserDatabaseRealm@add1c5
    valveNames: [Ljava.lang.String;@8d427c
    valveObjectNames: [Ljavax.management.ObjectName;@53dc4b
     
    */

    TCSKitty *kitty = (TCSKitty *)component;
    NSMutableArray *rHosts = [[NSMutableArray alloc] init];
    TCSHostComponent *host;
    TCSHostComponent *rHost = nil;
    if([rString characterAtIndex:0] == 'O') {
        // create hosts from response
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
                 Name: Catalina:type=Host,host=local.fivesquare.net
                 appBase: /Users/johnclay/Sites/fivesquaresoftware.com
                 autoDeploy: true
                 debug: 0
                 deployOnStartup: true
                 deployXML: true
                 unpackWARs: true
                 xmlNamespaceAware: false
                 xmlValidation: false
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
                            if([subValueName isEqualToString:@"host"]) {
                                rHost = 
                                [TCSHostComponent 
                                    withParent:kitty
                                          name:subValueValue components:nil];
                                [rHosts addObject:rHost];
                            }
                        }
                    }
                                
                } else if([name isEqualToString:@"appBase"] && rHost != nil) {
                    [rHost setAppBase:value];
                } else if([name isEqualToString:@"autoDeploy"] && rHost != nil) {
                    [rHost setAutoDeploy:value];
                } else if([name isEqualToString:@"debug"] && rHost != nil) {
                    [rHost setDebug:value];
                } else if([name isEqualToString:@"deployOnStartup"] && rHost != nil) {
                    [rHost setDeployOnStartup:value];
                } else if([name isEqualToString:@"deployXML"] && rHost != nil) {
                    [rHost setDeployXML:value];
                } else if([name isEqualToString:@"unpackWARs"] && rHost != nil) {
                    [rHost setUnpackWARs:value];
                } else if([name isEqualToString:@"xmlNamespaceAware"] && rHost != nil) {
                    [rHost setXmlNamespaceAware:value];
                } else if([name isEqualToString:@"xmlValidation"] && rHost != nil) {
                    [rHost setXmlValidation:value];
                    rHost = nil;
                } 
            }
        }
        
        // compare them to known hosts
        //  update, add, delete
        int k;
        for(k = 0; k < [rHosts count]; k++) {
            rHost = [rHosts objectAtIndex:k];
            if(![kitty containsComponent:rHost]) {
                logTrace(@"kitty.addComponent:%@",rHost);
                [kitty addComponent:rHost];
            } else {
                logTrace(@"kitty.updateComponent:%@",rHost);
                int idx = [kitty indexOfComponent:rHost];
                [[kitty componentAtIndex:idx] updateWithComponent:rHost];
            }
        }
        logTrace(@"kitty.components:%@",[kitty components]);
        int j;
        for (j = 0; j < [[kitty components] count]; j++) {
            id thisComponent = [[kitty components] objectAtIndex:j];
            if([thisComponent isMemberOfClass:[TCSHostComponent class]]) {
                if(![rHosts containsObject:thisComponent]) {
                    logTrace(@"kitty.removeComponent:%@",thisComponent);
                    [kitty removeComponent:thisComponent];
                }
            }
        }
        logTrace(@"kitty.components:%@",[kitty components]);
    } else {
        logError(@"Manager encountered an error");
    }
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationHostsInfoUpdateReceived 
                      object:kitty
                    userInfo:messages];
}

@end
