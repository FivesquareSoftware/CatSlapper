//
//  TCSUserShell.h
//  TomcatSlapper
//
//  Created by John Clayton on 10/14/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;


@interface TCSUserShell : NSObject {

}

+ (NSMutableDictionary *) currentEnvironmentFromUserShell; 

@end
