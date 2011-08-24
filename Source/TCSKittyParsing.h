//
//  TCSKittyParsing.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/27/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSKittyParsing : NSObject {
    TCSKitty *kitty;
    NSMutableArray *connectors;
}

- (id) initWithKitty:(TCSKitty *)aKitty;
+ (id) withKitty:(TCSKitty *)aKitty;

- (NSMutableArray *) connectors;

@end
