//
//  TCSKittyPermissionsUtility+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 2/11/06.
//  Copyright 2006 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSAuthorizationHandler.h"

@interface TCSKittyPermissionsUtility (Private)

+ (void) _repairDirectory:(NSString *)directoryPath withAuthorization:(AuthorizationRef)authRef;

@end
