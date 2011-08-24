//
//  TCSLaunchDaemonManager.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSLaunchDaemonManager : NSObject {
    NSMutableDictionary *daemons;
    NSMutableDictionary *agents;
}

- (void) installACLs;
- (void) setEnvironmentForKitty:(TCSKitty *)tk;
- (void) setAutomaticStartupTypeForKitty:(TCSKitty *)tk;
- (void) setRunPrivilegedForKitty:(TCSKitty *)tk;
- (void) setNameForKitty:(TCSKitty *)tk;
- (id) daemonForKitty:(TCSKitty *)tk;
- (id) agentForKitty:(TCSKitty *)tk;
+ (BOOL) didInstallACLs;

@end
