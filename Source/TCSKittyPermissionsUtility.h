//
//  TCSKittyPermissionsUtility.h
//  TomcatSlapper
//
//  Created by John Clayton on 2/11/06.
//  Copyright 2006 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSKittyPermissionsUtility : NSObject {

}

+ (BOOL) kittyPermissionsNeedRepair:(TCSKitty *)tk;
+ (void) repairPermissionsForKitty:(TCSKitty *)tk;

@end
