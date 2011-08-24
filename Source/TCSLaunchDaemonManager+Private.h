//
//  TCSLaunchDaemonManager+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/28/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSConstants.h"
#import "TCSAuthorizationHandler.h"

@class TCSKitty;

@interface TCSLaunchDaemonManager (Private) 

- (id) _initPlistForKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type;
- (id) _writePlist:(id)plist forKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type;
- (void) _moveFilesForKitty:(TCSKitty *)tk old:(NSString *)old new:(NSString *)new;
- (NSString *) _plistPathForKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type;
- (NSString *) _plistPathForKitty:(TCSKitty *)tk type:(TCSAutomaticStartupType)type basename:(NSString *)basename;
- (NSString *) _nameHashForKitty:(TCSKitty *)tk;
- (NSString *) _hashForName:(NSString *)name home:(NSString *)home base:(NSString *)base;
- (void) _enableACLs:(AuthorizationRef)authRef;
- (void) _addACLEntry:(AuthorizationRef)authRef;
    
@end
