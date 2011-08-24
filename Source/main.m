//
//  main.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/10/04.
//  Copyright Fivesquare Software, LLC 2004. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSSignalHandler.h"
//#import <Log4Cocoa/L4Configurator.h>

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [TCSSignalHandler installSignalHandler];
//    [L4Configurator basicConfiguration]; 
    [pool release];
    return NSApplicationMain(argc,  (const char **) argv);
}
