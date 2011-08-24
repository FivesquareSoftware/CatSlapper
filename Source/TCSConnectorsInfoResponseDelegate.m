//
//  TCSConnectorsInfoResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/21/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSConnectorsInfoResponseDelegate.h"
#import "TCSLogger.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSKitty.h"
#import "TCSComponent.h"
#import "TCSConnectorComponent.h"

@implementation TCSConnectorsInfoResponseDelegate

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing server info response %@",rString);
    /*
     OK - Number of results: 2
     
     Name: Catalina:type=Connector,port=8080
     modelerType: org.apache.catalina.mbeans.ConnectorMBean
     acceptCount: 100
     allowTrace: false
     bufferSize: 2048
     className: org.apache.coyote.tomcat5.CoyoteConnector
     clientAuth: false
     compression: off
     connectionLinger: -1
     connectionTimeout: 20000
     connectionUploadTimeout: 300000
     debug: 0
     disableUploadTimeout: true
     enableLookups: false
     maxHttpHeaderSize: 4096
     maxKeepAliveRequests: 100
     maxPostSize: 2097152
     maxProcessors: 20
     minProcessors: 5
     maxSpareThreads: 75
     maxThreads: 150
     minSpareThreads: 25
     minProcessors: 5
     port: 8080
     protocol: HTTP/1.1
     protocolHandlerClassName: org.apache.coyote.http11.Http11Protocol
     proxyPort: 0
     redirectPort: 8443
     scheme: http
     secure: false
     tcpNoDelay: true
     tomcatAuthentication: true
     threadPriority: 5
     useBodyEncodingForURI: false
     xpoweredBy: false
     
     * Name: Catalina:type=Connector,port=8009
     modelerType: org.apache.catalina.mbeans.ConnectorMBean
     acceptCount: 10
     allowTrace: false
     bufferSize: 2048
     className: org.apache.coyote.tomcat5.CoyoteConnector
     clientAuth: false
     compression: off
     connectionLinger: -1
     connectionTimeout: 60000
     connectionUploadTimeout: 300000
     debug: 0
     disableUploadTimeout: false
     enableLookups: false
     maxHttpHeaderSize: 4096
     maxKeepAliveRequests: 100
     maxPostSize: 2097152
     maxProcessors: 20
     minProcessors: 5
     minProcessors: 5
     * port: 8009
     * protocol: AJP/1.3
     protocolHandlerClassName: org.apache.jk.server.JkCoyoteHandler
     proxyPort: 0
     redirectPort: 8443
     * scheme: http
     secure: false
     tcpNoDelay: true
     tomcatAuthentication: true
     threadPriority: 5
     useBodyEncodingForURI: false
     xpoweredBy: false
     */

    TCSKitty *kitty = (TCSKitty *)component;
    NSMutableArray *rConnectors = [[NSMutableArray alloc] init];
    TCSConnectorComponent *connector;
    TCSConnectorComponent *rConnector = nil;
    if([rString characterAtIndex:0] == 'O') {
        // create connectors from response
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
                 Name: Catalina:type=Connector,port=8009
                 port: 8009
                 protocol: AJP/1.3
                 scheme: http
                 secure: false
                 */
                if([name isEqualToString:@"Name"]) {
                    rConnector = 
                        [TCSConnectorComponent 
                            withParent:kitty
                                  name:nil components:nil];
                    [rConnectors addObject:rConnector];
                    logTrace(@"rConnector: %@",rConnector);
                } else if([name isEqualToString:@"port"] && rConnector != nil) {
                    [rConnector setPort:value];
                } else if([name isEqualToString:@"protocol"] && rConnector != nil) {
                    [rConnector setProtocol:value];
                } else if([name isEqualToString:@"scheme"] && rConnector != nil) {
                    [rConnector setScheme:value];
                } else if([name isEqualToString:@"scheme"] && rConnector != nil) {
                    [rConnector setIsSecure:value];
                    rConnector = nil;
                } 
            }
        }
        
        // compare them to known connectors
        //  update, add, delete
        int k;
        for(k = 0; k < [rConnectors count]; k++) {
            rConnector = [rConnectors objectAtIndex:k];
            if(![kitty containsComponent:rConnector]) {
                logTrace(@"kitty.addComponent:%@",rConnector);
                [kitty addComponent:rConnector];
            } else {
                logTrace(@"kitty.updateComponent:%@",rConnector);
                int idx = [kitty indexOfComponent:rConnector];
                [[kitty componentAtIndex:idx] updateWithComponent:rConnector];
            }
        }
        logTrace(@"kitty.components:%@",[kitty components]);
        int j;
        for (j = 0; j < [[kitty components] count]; j++) {
            id thisComponent = [[kitty components] objectAtIndex:j];
            if([thisComponent isMemberOfClass:[TCSConnectorComponent class]]) {
                if(![rConnectors containsObject:thisComponent]) {
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
        postNotificationName:TCSNotifcationConnectorsInfoUpdateReceived 
                      object:kitty
                    userInfo:messages];   
     
}


@end
