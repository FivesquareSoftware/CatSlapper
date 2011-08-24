//
//  TCSServerStatusResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 4/17/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSServerStatusResponseDelegate.h"
#import "TCSLogger.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"
#import "TCSKitty.h"

@implementation TCSServerStatusResponseDelegate

- (void) dealloc {
    [super dealloc];
}

- (void) handleResponse {
    //parse response
    logTrace(@"Parsing server status response %@",rString);
    
    kitty = (TCSKitty *)component;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:responseData];
    [parser setDelegate:self];
    if(![parser parse]) {
        logError(@"error parsing server status response (%@)",[parser parserError]);
    }
    
    //call callback
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationServerStatusUpdateReceived 
                      object:kitty
                    userInfo:nil];    
}


/*
 <?xml version="1.0" encoding="utf-8"?>
 <?xml-stylesheet type="text/xsl" href="/manager/xform.xsl" ?>
 <status>
	<jvm>
 <memory free='4269048' total='26648576' max='150994944' />
	</jvm>
	<connector name='http-8080'>
             <threadInfo maxThreads="150" minSpareThreads="25" maxSpareThreads="75" currentThreadCount="25" currentThreadsBusy="2" />
             <requestInfo maxTime="1998" processingTime="328943" requestCount="4218" errorCount="79" bytesReceived="87" bytesSent="117033168" />
             <workers>
             <worker stage="R" requestProcessingTime="0" requestBytesSent="0" requestBytesRecieved="0" remoteAddr="&#63;" virtualHost="&#63;" method="&#63;" currentUri="&#63;" currentQueryString="&#63;" protocol="&#63;" />
             <worker stage="R" requestProcessingTime="0" requestBytesSent="0" requestBytesRecieved="0" remoteAddr="&#63;" virtualHost="&#63;" method="&#63;" currentUri="&#63;" currentQueryString="&#63;" protocol="&#63;" />
             <worker stage="R" requestProcessingTime="0" requestBytesSent="0" requestBytesRecieved="0" remoteAddr="&#63;" virtualHost="&#63;" method="&#63;" currentUri="&#63;" currentQueryString="&#63;" protocol="&#63;" />
             <worker stage="R" requestProcessingTime="0" requestBytesSent="0" requestBytesRecieved="0" remoteAddr="&#63;" virtualHost="&#63;" method="&#63;" currentUri="&#63;" currentQueryString="&#63;" protocol="&#63;" />
             <worker stage="S" requestProcessingTime="1" requestBytesSent="0" requestBytesReceived="0" remoteAddr="0:0:0:0:0:0:0:1" virtualHost="localhost" method="GET" currentUri="/manager/status/all" currentQueryString="XML=true" protocol="HTTP/1.1" />
             <worker stage="R" requestProcessingTime="0" requestBytesSent="0" requestBytesRecieved="0" remoteAddr="&#63;" virtualHost="&#63;" method="&#63;" currentUri="&#63;" currentQueryString="&#63;" protocol="&#63;" />
             </workers>
	</connector>
	<connector name='jk-8009'>
             <threadInfo maxThreads="200" minSpareThreads="4" maxSpareThreads="50" currentThreadCount="4" currentThreadsBusy="1" />
             <requestInfo maxTime="0" processingTime="0" requestCount="0" errorCount="0" bytesReceived="0" bytesSent="0" />
             <workers>
             </workers>
	</connector>
 </status>
 */ 

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    logTrace(@"parsing server status response");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    logTrace(@"done parsing server status response");    
}

- (void) parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qualifiedName 
     attributes:(NSDictionary *)attributeDict {
    logTrace(@"didStartElement:%@",elementName);
    if([elementName isEqualToString:@"memory"]) {
        [self handleMemory:attributeDict];
    } else if([elementName isEqualToString:@"connector"]) {
        [self handleConnector:attributeDict];
    } else if([elementName isEqualToString:@"threadInfo"]) {
        [self handleThreadInfo:attributeDict];
    } else if([elementName isEqualToString:@"requestInfo"]) {
        [self handleRequestInfo:attributeDict];
    }
}

- (void) parser:(NSXMLParser *)parser 
  didEndElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qualifiedName {
    logTrace(@"didEndElement:%@",elementName);
}

- (void) handleMemory:(NSDictionary *)attributeDict {
    //Free memory: 2.37 MB Total memory: 25.41 MB Max memory: 144.00 MB
    // <memory free='2946760' total='26648576' max='150994944' />
    logTrace(@"attributeDict: %@",attributeDict);
    [kitty setFreeMemory:[attributeDict objectForKey:@"free"]];
    [kitty setTotalMemory:[attributeDict objectForKey:@"total"]];
    [kitty setMaxMemory:[attributeDict objectForKey:@"max"]];
}

- (void) handleConnector:(NSDictionary *)attributeDict {    
    //	<connector name='http-8080'>    
    NSString *name = [attributeDict objectForKey:@"name"];
    NSRange dashRange = [name rangeOfString:@"-"];
    NSString *port = [name substringFromIndex:dashRange.location+1];
    logTrace(@"port: %@",port);
    int j;
    for (j = 0; j < [kitty numberOfComponents]; j++) {
        id thisComponent = [kitty componentAtIndex:j];
        logTrace(@"thisComponentAtIndex:%d = %@",j,thisComponent);
        if([thisComponent isMemberOfClass:[TCSConnectorComponent class]]) {
            logTrace(@"thisComponent.port: %@",[(TCSConnectorComponent *)thisComponent port]);
            if([[(TCSConnectorComponent *)thisComponent port] isEqualToString:port]) {
                logTrace(@"connector = %@",thisComponent);
                connector = thisComponent;
                break;
            }
        }
    }
}

- (void) handleThreadInfo:(NSDictionary *)attributeDict {
    //<threadInfo maxThreads="150" minSpareThreads="25" maxSpareThreads="75" currentThreadCount="25" currentThreadsBusy="2" />
    //Max threads: 150 Min spare threads: 25 Max spare threads: 75 Current thread count: 25 Current thread busy: 2
    logTrace(@"connector:%@",connector);
    if(connector != nil) {
        logTrace(@"attributeDict: %@",attributeDict);
        [connector setMaxThreads:[attributeDict objectForKey:@"maxThreads"]];
        [connector setMinSpareThreads:[attributeDict objectForKey:@"minSpareThreads"]];
        [connector setMaxSpareThreads:[attributeDict objectForKey:@"maxSpareThreads"]];
        [connector setCurrentThreadCount:[attributeDict objectForKey:@"currentThreadCount"]];
        [connector setCurrentThreadsBusy:[attributeDict objectForKey:@"currentThreadsBusy"]];
    }
}

- (void) handleRequestInfo:(NSDictionary *)attributeDict {
    //<requestInfo maxTime="1998" processingTime="328943" requestCount="4218" errorCount="79" bytesReceived="87" bytesSent="117033168" />
    //Max processing time: 1998 ms Processing time: 322 s Request count: 4121 Error count: 49 Bytes received: 0.00 MB Bytes sent: 109.86 MB
    if(connector != nil) {
        logTrace(@"attributeDict: %@",attributeDict);
        [connector setMaxTime:[attributeDict objectForKey:@"maxTime"]];
        [connector setProcessingTime:[attributeDict objectForKey:@"processingTime"]];
        [connector setRequestCount:[attributeDict objectForKey:@"requestCount"]];
        [connector setErrorCount:[attributeDict objectForKey:@"errorCount"]];
        [connector setBytesReceived:[attributeDict objectForKey:@"bytesReceived"]];
        [connector setBytesSent:[attributeDict objectForKey:@"bytesSent"]];
    }
}


@end
