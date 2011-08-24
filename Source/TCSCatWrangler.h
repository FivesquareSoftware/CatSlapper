//
//  TCSCatWrangler.h
//  TomcatSlapper
//
//  Created by John Clayton on 10/30/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;
@class TCSProcess;


@interface TCSCatWrangler : NSObject {
}

- (void) validateKittyProcess:(TCSKitty *)tk;
- (TCSKitty *) newKittyFromProcess:(TCSProcess *)process;
- (NSString *) javaHomeFromJavaCommand:(NSString *)command;
- (NSDictionary *) extractProcessEnvironmentFromArgs:(NSArray *)args;
- (void) validateKitty:(TCSKitty *)tk inKittens:(NSMutableArray *)kittens;
- (void) configureKittyWithServerConfig:(TCSKitty *)tk;

@end
