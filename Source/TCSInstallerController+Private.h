//
//  TCSInstallerController+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/14/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSInstallerController (Private)

- (void) _tmuClr;
- (void) _tmpClr;
- (id) _init;
- (void) _initKitty;
- (NSString *) _incrementPort:(NSString *)port;
- (int) _kittyCount;    
- (void) _authorizedInstall:(TCSKitty *)tk;
- (void) _generateStdErrHandle;
- (NSMutableArray *) _installerArgsForKitty:(TCSKitty *)tk;
- (void) _readInstallerOut:(FILE *)installerPipe;

@end
