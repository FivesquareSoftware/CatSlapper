//
//  TCSCatSlapper+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 10/3/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCSKitty;
@class TCSProcess;

@interface TCSCatSlapper (Private) 
- (void) _configureKitties;
- (void) _upgradeKitties;
- (void) _makeBindings;
- (void) _createConsoleServers;
- (void) _cleanupConsoleServers; 
- (void) _saveKittensToDefaults;
- (void) _updateKittyProcesses;
- (void) _setShadowNames;
- (void) _validateSystemBootForKitty:(TCSKitty *)tk;
- (void) _timedRevertStartup;
- (void) _revertStartup;
- (void) _timedRevertRunPrivileged;
- (void) _revertRunPrivileged;
    
@end
