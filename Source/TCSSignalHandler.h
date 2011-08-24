//
//  TCSSignalHandler.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/22/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


void _signalHandler(int signo);

@interface TCSSignalHandler : NSObject {

}

+ (void) installSignalHandler;
- (void) handleMachMessage:(void *)machMessage;

@end
