//
//  TCSServerStatusResponseDelegate.h
//  TomcatSlapper
//
//  Created by John Clayton on 4/17/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSTomcatManagerResponseDelegate.h"
#import "TCSConnectorComponent.h"

@class TCSKitty;

@interface TCSServerStatusResponseDelegate 
: TCSTomcatManagerResponseDelegate <TCSTomcatManagerResponseDelegateProtocol> {
    id connector;
    TCSKitty *kitty;
}

- (void) handleMemory:(NSDictionary *)attributeDict;
- (void) handleConnector:(NSDictionary *)attributeDict;
- (void) handleThreadInfo:(NSDictionary *)attributeDict;
- (void) handleRequestInfo:(NSDictionary *)attributeDict;
@end
