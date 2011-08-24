//
//  TCSStartupItemManager.h
//  TomcatSlapper
//
//  Created by John Clayton on 5/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;
@class TCSAuthorizationHandler;

@interface TCSStartupItemManager : NSObject {
    NSString *enableStartupItemPath;
    NSString *disableStartupItemPath;
    
    TCSAuthorizationHandler *authHandler;
}

- (void) updateStartupItemForKitty:(TCSKitty *)tk;
- (void) removeStartupItemForKitty:(TCSKitty *)tk;

@end
