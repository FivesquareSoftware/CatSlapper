//
//  TCSKittyParsing.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/27/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSKittyParsing.h"
#import "TCSLogger.h"
#import "TCSKitty.h"
#import "TCSConnectorComponent.h"

@implementation TCSKittyParsing


- (id) initWithKitty:(TCSKitty *)aKitty {
    if(self = [super init]) {
        kitty = [aKitty retain];
        connectors = [[NSMutableArray array] retain];
    }
    return self;
}

+ (id) withKitty:(TCSKitty *)aKitty {
    return [[[TCSKittyParsing alloc] initWithKitty:aKitty] autorelease];
}

- (void) dealloc {
    [kitty release];
    [connectors release];
    [super dealloc];
}


- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict {
    logTrace(@"parser:%@ didStartElement:%@",parser,elementName);
    if([elementName isEqualToString:@"Connector"]) {
        logTrace(@"connector atts = %@",attributeDict);
        TCSConnectorComponent *connector = [[TCSConnectorComponent alloc] init];
        [connector setProtocol:[attributeDict objectForKey:@"protocol"]];
        [connector setPort:[attributeDict objectForKey:@"port"]];
        [connector setScheme:[attributeDict objectForKey:@"scheme"]];
        NSString *isSecure = [attributeDict objectForKey:@"secure"];
        [connector setIsSecure:isSecure];
        [connectors addObject:connector];
    }
    if([elementName isEqualToString:@"Server"]) {
        [kitty setShutdownPort:[attributeDict objectForKey:@"port"]];
    }
}

- (NSMutableArray *) connectors {
    return connectors;
}


@end
