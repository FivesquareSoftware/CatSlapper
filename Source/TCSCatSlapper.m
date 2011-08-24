//
//  TCSCatSlapper.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/20/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSCatSlapper.h"
#import "TCSCatSlapper+Private.h"
#import "TCSCatWrangler.h"
#import "TCSCatSpanker.h"
#import "TCSController.h"
#import "TCSConstants.h"
#import "TCSKitty.h"
#import "TCSKittyParsing.h"
#import "TCSLogger.h"
#import "TCSPrefController.h"
#import "TCSConsoleView.h"
#import "TCSTomcatManagerProxy.h"
#import "TCSProcess.h"
#import "TCSLaunchDaemonManager.h"
#import "TCSKittyArrayController.h"
#import "TCSComponentViewDataSource.h"
#import "TCSKittyPermissionsUtility.h"

#import <ExceptionHandling/NSExceptionHandler.h>

@implementation TCSCatSlapper

// OBJECT STUFF ============================================================= //

- (id) init {
    if(self = [super init]) {        
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        //read from user defaults
        NSData *kittensAsData = [defs dataForKey:TCSUserDefaultsKittens];  
        if(kittensAsData != nil) {
            kittens = [[NSKeyedUnarchiver unarchiveObjectWithData:kittensAsData] mutableCopy];
        } else {
            kittens = [NSMutableArray array];
        }
        [kittens retain];
        [self _upgradeKitties];
        logDebug(@"kittens = %@",kittens);
    }       
    return self;
}

- (void) dealloc {
    [kittens release];
    [serverUpdateTimer release];
    [componentUpdateTimer release];
    [super dealloc];
}

- (void) awakeFromNib {    
    logTrace(@"awakeFromNib.selectionIndex = %d",[kittyController selectionIndex]);
    // we do this once, but when catalina* stuff changes in the future, 
    // we only do it if there are no config errors 
    [self _configureKitties];
    [self _makeBindings];    
    int idx = [[NSUserDefaults standardUserDefaults] integerForKey:TCSUserDefaultsSelectedKitty];
    logTrace(@"userDefaults.idx = %d",idx);
    logTrace(@"kittens.count = %d",[kittens count]);
    if(idx <= [kittens count])
        [kittyController setSelectionIndex:idx];
    [self _updateKittyProcesses];    
    [self _createConsoleServers];
    [self _setShadowNames];
    [self showLogForSelectedKitten];
    [self validateSelectedKitten];
    [componentView reloadData];
    
    serverUpdateTimer = 
        [[NSTimer 
            scheduledTimerWithTimeInterval:10 //TODO store in defaults?
                                    target:self 
                                  selector:@selector(_updateKittyProcesses) 
                                  userInfo:nil 
                                   repeats:YES] retain]; 
    NSTimeInterval updateComponentsEvery = 
        [[[TCSPrefController sharedPrefController] componentUpdatesEvery]  doubleValue];
    componentUpdateTimer =
        [[NSTimer 
            scheduledTimerWithTimeInterval: updateComponentsEvery
                                    target:self 
                                  selector:@selector(updateComponentsForSelectedKitty) 
                                  userInfo:nil 
                                   repeats:YES] retain];
    
}



// KVO API ================================================================== //
#pragma mark KVO API

- (unsigned int)countOfKittens {
    return [kittens count];
}

- (id)objectInKittensAtIndex:(unsigned int)index {
    return [kittens objectAtIndex:index];
}

- (void)insertObject:(id)anObject inKittensAtIndex:(unsigned int)index {
    logDebug(@"insertObject:%@",anObject);
    NSString *name = [(TCSKitty *)anObject name];
    if(name == nil) {
        [(TCSKitty *)anObject setName:[NSString stringWithFormat:@"untitled %d",[kittens count]]];
    }
    
    [kittens insertObject:anObject atIndex:index];
    [consoleView createConsoleServer:[anObject logfile]];
    
    //this binding seems to ignore nil placeholder of 0, set here instead
    if([kittens count] == 1) {
        [kittySelector bind: @"selectedIndex" toObject: kittyController
                withKeyPath:@"selectionIndex" options:nil];
    }
}

- (void)removeObjectFromKittensAtIndex:(unsigned int)index {
    logDebug(@"removeObjectFromKittensAtIndex:%d",index);
    TCSKitty *tk = [kittens objectAtIndex:index];
    // disable auto startup
    [tk setAutomaticStartupType:TCS_NEVER];

    [kittens removeObjectAtIndex:index];

    //this binding seems to ignore nil placeholder of 0, unbind here
    if([kittens count] < 1) {
        [kittySelector unbind:@"selectedIndex"];
    }
}

- (void)replaceObjectInKittensAtIndex:(unsigned int)index withObject:(id)anObject {
    [kittens replaceObjectAtIndex:index withObject:anObject];
    [self _saveKittensToDefaults];
}


// UTILS ==================================================================== //

#pragma mark Utils

- (NSArray *) kittens {
    return kittens;
}

- (TCSKitty *) selectedKitty {
    TCSKitty *tk = nil;
    int idx = [kittyController selectionIndex];
    if(idx != NSNotFound) {
        tk = [self objectInKittensAtIndex:idx];
    }
    return tk;
}

- (int) nameInUse:(NSString *)aName {
    int isEqualCount = 0;
    int i, count = [kittens count];
    for (i = 0; i < count; i++) {
        TCSKitty *tk = (TCSKitty *)[kittens objectAtIndex:i];
        if([[tk name] isEqualToString:aName]) {
            isEqualCount++;
        }
    }
    return isEqualCount;
}

- (void) reconfigureSelectedKittenFromServerConfig {
    TCSKitty *tk = [self selectedKitty];
    if(tk != nil) {
        logDebug(@"Reconfiguring kitten %@",tk);
        [wrangler configureKittyWithServerConfig:tk];
    }
}

- (void) validateProcessForSelectedKitty {
    TCSKitty *tk = [self selectedKitty];
    if(tk != nil) {
        [wrangler validateKittyProcess:tk];
    }
}

- (void) validateSelectedKitten {
    TCSKitty *tk = [self selectedKitty];
    if(tk != nil) {
        logDebug(@"validating kitten %@",tk);
        [wrangler validateKitty:tk inKittens:kittens];
    }
}

- (void) showLogForSelectedKitten {
    logDebug(@"showLogForSelectedKitten");
    TCSKitty *tk = [self selectedKitty];
    logDebug(@"tk.logfile = %@",[tk logfile]);
    [consoleView setActiveFile:[tk logfile]];
}

- (BOOL) kittyPermissionsNeedRepair:(TCSKitty *)tk {
    return [TCSKittyPermissionsUtility kittyPermissionsNeedRepair:tk];
}

- (void) repairPermissionsForKitty:(TCSKitty *)tk {
    logDebug(@"repairPermissionsForKitty");
    [TCSKittyPermissionsUtility repairPermissionsForKitty:tk];
}

- (void) repairPermissions {
    logDebug(@"repairPermissions");
    // if the user has ok'd us to repair permissions without asking
    //BOOL shouldAsk = 
    //    [[NSUserDefaults standardUserDefaults] 
    //        boolForKey:TCSUserDefaultsShouldAskAboutRepairingPermissions];
    //logDebug(@"shouldAsk = %d",shouldAsk);
    //if(!shouldAsk) {
        logDebug(@"looking for broken");
        unsigned int i, count = [kittens count];
        for (i = 0; i < count; i++) {
            TCSKitty *tk = [kittens objectAtIndex:i];
            if(![tk runPrivileged] && [self kittyPermissionsNeedRepair:tk]) {
                @try {
                    [self repairPermissionsForKitty:tk];
                }
                @catch (NSException * e) {
                    [appController warnUserThatRepairingPermissionsFailed:self];
                    logError(@"Error repairing permissions:%@",e);
                }
            }
        }
   // }
}

- (void) syncLaunchdForKitty:(TCSKitty *)tk {
    logDebug(@"syncLaunchdForKitty:%@",tk);
    [launchDaemonManager setAutomaticStartupTypeForKitty:tk];
    [launchDaemonManager setEnvironmentForKitty:tk];
    [launchDaemonManager setRunPrivilegedForKitty:tk];
    [launchDaemonManager setNameForKitty:tk];
}

- (void) syncLaunchd {
    @try {
        unsigned int i, count = [kittens count];
        for (i = 0; i < count; i++) {
            TCSKitty *tk = [kittens objectAtIndex:i];
            if([tk validationErrors] == nil) {
                [self syncLaunchdForKitty:tk];
            }
        }
    }
    @catch (NSException * e) {
        [appController warnUserThatSyncingLaunchDaemonsFailed:self];
        logError(@"Error syncing launch daemons:%@",e);
    }
}



// IBACTIONS ================================================================ //

#pragma mark Interface Methods

- (IBAction) selectKitty:(id) sender {
    logDebug(@"kittySelector.selectedIndex = %d",[kittySelector indexOfSelectedItem]);
    logDebug(@"kittyController.selectionIndex = %d",[kittyController selectionIndex]);
}

- (IBAction) updateComponentsForSelectedKitty:(id)sender {
    logDebug(@"updateComponentsForSelectedKitty: %@",sender);
    TCSKitty *tk = [self selectedKitty];
    if(tk != nil &&
       (![[TCSPrefController sharedPrefController] manualComponentUpdates]
        || sender != self)) {
        NSDictionary *args = 
            [NSDictionary dictionaryWithObjectsAndKeys:
                tk 
                ,TCSComponentUpdateArgKitty
                ,[NSNumber numberWithBool:(sender != self)]
                ,TCSComponentUpdateArgForced, nil];
//        [NSThread detachNewThreadSelector:@selector(updateComponentsForKittyInDictionary:) 
//                                 toTarget:managerProxy withObject:args];
        [managerProxy updateComponentsForKitty:tk force:(sender != self)];
    } 
}

- (void) updateComponentsForSelectedKitty {
    logDebug(@"updateComponentsForSelectedKitty");
    [self updateComponentsForSelectedKitty:self];
}


- (void) addKitten:(NSNotification *)notification {
    id tk = [notification object];
    [kittyController performSelectorOnMainThread:@selector(addObject:) 
                                      withObject:tk 
                                   waitUntilDone:YES];
}

- (IBAction) toggleKitty:(id) sender {
    TCSKitty *tk = [self selectedKitty];
    logTrace(@"tk.isRunning = %d",[tk isRunning]);
    //TODO when kitty starts, re-read server config because it may be different
    NSDictionary *output = [TCSCatSpanker toggleTomcat:tk];
    NSString *logFileName = [kittyController valueForKeyPath:@"selection.logfile"];
    logDebug(@"output.objectForKey(TCS_STDOUT): %@"
             ,[output objectForKey:[NSNumber numberWithInt:TCS_STDOUT]]);
    [consoleView appendString:[output objectForKey:[NSNumber numberWithInt:TCS_STDOUT]] 
                      forFile:logFileName
                         type:TCS_STDOUT];
    logDebug(@"output.objectForKey(TCS_STDERR): %@"
             ,[output objectForKey:[NSNumber numberWithInt:TCS_STDERR]]);
    [consoleView appendString:[output objectForKey:[NSNumber numberWithInt:TCS_STDERR]] 
                      forFile:logFileName
                         type:TCS_STDERR];
}

- (IBAction) restartKitty:(id) sender {
    TCSKitty *tk = [self selectedKitty];
    [self toggleKitty:self];
    if(![tk isRunning]) [self toggleKitty:self];
}

// TAB VIEW DELEGATE ======================================================== //

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    logDebug(@"willSelectTabViewItem:%@",[tabViewItem identifier]);
    if([[tabViewItem identifier] isEqual:@"2"]) {
        [componentView reloadData];
//        [self updateComponentsForSelectedKitty];
    }
}

// DOCK MENU DELEGATE ======================================================== //

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
    logDebug(@"validateMenuItem:%@",menuItem);
    // a heinous hack because dock menu delegate doesn't work
    if([menuItem tag] == DOCK_MENU_KITTY_ITEM_TAG) {
        TCSKitty *tk = [self selectedKitty];
        [menuItem setTitle:[tk name]];
    }
    return YES;
}


// a heinous hack because the method below never gets called
- (IBAction) updateDockMenu:(id)sender {
    //do nothing
}

//TODO:  NEVER GETS CALLED FILE A BUG
- (BOOL) menu:(NSMenu *)menu 
   updateItem:(NSMenuItem *)item 
      atIndex:(int)index 
 shouldCancel:(BOOL)shouldCancel {
    logDebug(@"menu:%@ updateItem:%@",menu,item);
    if([item tag] == DOCK_MENU_KITTY_ITEM_TAG) {
        TCSKitty *tk = [self selectedKitty];
        [item setTitle:[tk name]];
    }
    return YES;
}

// TOOLBAR TARGET =========================================================== //

#pragma mark Toolbar target

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem { 
	return YES;
}



// OBSERVATIONS ============================================================= //

#pragma mark Observations

- (void) registerObservations {
    [kittyController addObserver:self
                      forKeyPath:@"selection" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.name" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.javaHome" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.catalinaHome" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.catalinaBase" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.catalinaOpts" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.useDefaults" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];    
    [kittyController addObserver:self
                      forKeyPath:@"selection.logfile" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];
    [kittyController addObserver:self
                      forKeyPath:@"selection.automaticStartupType" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];
    [kittyController addObserver:self
                      forKeyPath:@"selection.runPrivileged" 
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];
    [[NSNotificationCenter defaultCenter] 
            addObserver:self 
               selector:@selector(addKitten:) 
                   name:TCSNotifcationTomcatInstalled 
                 object:nil];
/*
 [[NSNotificationCenter defaultCenter] 
            addObserver:self 
               selector:@selector(loadRegistration) 
                   name:TCSNotifcationRegistrationChanged
                 object:nil];
 */
    [[TCSPrefController sharedPrefController] 
                addObserver:self 
                 forKeyPath:@"componentUpdatesEvery" 
                    options:(NSKeyValueObservingOptionNew |
                             NSKeyValueObservingOptionOld)
                    context:NULL];
}

- (void) removeObservations {
    [kittyController removeObserver:self forKeyPath:@"selection"];    
    [kittyController removeObserver:self forKeyPath:@"selection.name"];    
    [kittyController removeObserver:self forKeyPath:@"selection.javaHome"];    
    [kittyController removeObserver:self forKeyPath:@"selection.catlinaHome"];    
    [kittyController removeObserver:self forKeyPath:@"selection.catlinaBase"];    
    [kittyController removeObserver:self forKeyPath:@"selection.catlinaOpts"];    
    [kittyController removeObserver:self forKeyPath:@"selection.useDefaults"];    
    [kittyController removeObserver:self forKeyPath:@"selection.logfile"];    
    [kittyController removeObserver:self forKeyPath:@"selection.automaticStartupType"];    
    [kittyController removeObserver:self forKeyPath:@"selection.runPrivileged"];    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[TCSPrefController sharedPrefController] 
        removeObserver:self forKeyPath:@"componentUpdatesEvery"];   
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    logDebug(@"observeValueForKeyPath:%@ ofObject:%@ change:%@",keyPath,object,change);

    //BUG: Apple- old and new don't work!!
    
    TCSKitty *tk = [self selectedKitty];

    if([keyPath isEqualToString:@"selection.name"]) {
        [self _setShadowNames];
        if([tk nameChanged]) {
            [launchDaemonManager setNameForKitty:tk];
        }
        // no more changes
        [tk set_name:[tk name]];
    }
    
    if([keyPath isEqualToString:@"selection"]) {
        [self validateProcessForSelectedKitty];
        [self showLogForSelectedKitten];
        [self updateComponentsForSelectedKitty];
        [componentView reloadData];
        [[componentView dataSource] postMessage:@""];
    } /*else if([keyPath isEqualToString:@"selection.catalinaHome"]
              || [keyPath isEqualToString:@"selection.catalinaBase"]) {
        if([tk catalinaHomeChanged] || [tk catalinaBaseChanged]) {
            // the server config may be different
            [self reconfigureSelectedKittenFromServerConfig];
        }
    }*/ else if([keyPath isEqualToString:@"selection.logfile"]) {
        //there may be a new logfile
        if((tk != nil && [tk validationErrors] == nil) || [tk _catalinaHome] == nil /* should catch a newly created cat*/) {
            //won't create a dupe, so ok
            [consoleView createConsoleServer:[tk logfile]];
        }
        [self showLogForSelectedKitten];
        //destroy any stragglers
        [self _cleanupConsoleServers];
    } else if([keyPath isEqualToString:@"selection.automaticStartupType"]
              && [tk automaticStartupTypeChanged]) {
        if([tk automaticStartupType] == TCS_SYSTEM_BOOT) {
            [self _validateSystemBootForKitty:tk];
        } else {
            [launchDaemonManager setAutomaticStartupTypeForKitty:tk];
            // no more change notices for this value
            [tk set_automaticStartupType:[tk automaticStartupType]];
        }
    } else if([keyPath isEqualToString:@"selection.runPrivileged"]
              && [tk runPrivilegedChanged]) {
        logDebug(@"runPrivileged changed to: %d",[tk runPrivileged]);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if([tk runPrivileged]) {
            BOOL okToRunPrivileged = YES;
            if([defaults boolForKey:TCSUserDefaultsShouldAskAboutRunningPrivileged]) {
                [appController askUserIfWeCanRunPrivileged:self];
                okToRunPrivileged = [defaults boolForKey:TCSUserDefaultsCanRunTomcatsPrivileged];
            }
            if(okToRunPrivileged) {
                [launchDaemonManager setRunPrivilegedForKitty:tk];                
                // no more change notices for this value
                [tk set_runPrivileged:[tk runPrivileged]];
            } else {
                [self _timedRevertRunPrivileged];
            }
        } else {
            [launchDaemonManager setRunPrivilegedForKitty:tk];
            // no more change notices for this value
            [tk set_runPrivileged:[tk runPrivileged]];
            if([self kittyPermissionsNeedRepair:tk]) {
                BOOL okToRepairPrivileges = YES;
                if([defaults boolForKey:TCSUserDefaultsShouldAskAboutRepairingPermissions]) {
                    [appController askUserIfWeCanRepairPermissions:self];
                    okToRepairPrivileges = [defaults boolForKey:TCSUserDefaultsCanRepairPermissions];
                }
                logDebug(@"okToRepairPrivileges=%d",okToRepairPrivileges);
                if(okToRepairPrivileges) {
                    [self repairPermissionsForKitty:tk];                
                }
            }
        }
    }
        
    if([keyPath rangeOfString:@"selection.catalina"].location != NSNotFound
       || [keyPath isEqualToString:@"selection.javaHome"]) {
        if([tk catalinaHomeChanged] || [tk catalinaBaseChanged] 
           || [tk catalinaOptsChanged] || [tk javaHomeChanged])  {
            if([tk validationErrors] == nil || ([tk _catalinaHome] == nil) /* this should catch new ones */ ) {
                logDebug(@"Configuring from server.xml");
                [self reconfigureSelectedKittenFromServerConfig];
                [launchDaemonManager setEnvironmentForKitty:tk];
            }
            // no more change notices for these values
            [tk set_javaHome:[tk javaHome]];
            [tk set_catalinaHome:[tk catalinaHome]];
            [tk set_catalinaBase:[tk catalinaBase]];
            [tk set_catalinaOpts:[tk catalinaOpts]];
        }
    }
        
    // after change handlers are complete
    if([keyPath rangeOfString:@"selection"].location != NSNotFound) {
        // we always save kittens! better safe than sorry
        [self _saveKittensToDefaults];
        // we always revalidate kittens
        [self validateSelectedKitten];
    }
    if([keyPath isEqualToString:@"componentUpdatesEvery"]) {
        [componentUpdateTimer invalidate];
        [componentUpdateTimer release];
        componentUpdateTimer = nil;

        NSTimeInterval updateComponentsEvery = 
            [[[TCSPrefController sharedPrefController] componentUpdatesEvery]  doubleValue];
        componentUpdateTimer =
            [[NSTimer 
                scheduledTimerWithTimeInterval: updateComponentsEvery
                                        target:self 
                                      selector:@selector(updateComponentsForSelectedKitty) 
                                      userInfo:nil 
                                       repeats:YES] retain];         
    }
}

// CLEANUP ================================================================== //


- (void) cleanup {
    logDebug(@"Saving kittens");
    [self _saveKittensToDefaults];
}

@end



// PRIVATE ================================================================== //

@implementation TCSCatSlapper (Private)

- (void) _configureKitties {
    logDebug(@"_configureKitties");
    logDebug(@"kittens = %@",kittens);
    unsigned int i, count = [kittens count];
    logDebug(@"count = %d",count);
    for (i = 0; i < count; i++) {
        TCSKitty *tk = [kittens objectAtIndex:i];
        logDebug(@"tk = %@",tk);
        logDebug(@"wrangler = %@",wrangler);
        [wrangler configureKittyWithServerConfig:tk];
    }
}

- (void) _upgradeKitties {
    unsigned int i, count = [kittens count];
    for (i = 0; i < count; i++) {
        TCSKitty *tk = [kittens objectAtIndex:i];
        if([tk startCommand] == nil)
            [tk setStartCommand:@"start"];
    }
}

- (void) _makeBindings {
    // bind array controller to self's itemsArray
    [kittyController bind:@"contentArray" toObject: self
              withKeyPath:@"kittens" options:nil];
    //this binding seems to ignore nil placeholder of 0
    // try here, and then again at object insertion
    if([kittens count] > 0) {
        [kittySelector bind: @"selectedIndex" toObject: kittyController
                withKeyPath:@"selectionIndex" options:nil];
    }
}

- (void) _createConsoleServers {
    // create a console server for each server
    // console client will refuse if it's a duplicate
    int k;
    for(k = 0; k < [kittens count]; k++) {
        TCSKitty *tk = [kittens objectAtIndex:k];
        if([tk logfile] != nil)
            [consoleView createConsoleServer:[tk logfile]];
    }
}

- (void) _cleanupConsoleServers {
    logDebug(@"_cleanupConsoleServers");
    NSArray *filenames = [consoleView filenames];
    logDebug(@"validating filenames: %@",filenames);
    unsigned int i, count = [filenames count];
    for (i = 0; i < count; i++) {
        NSString *filename = (NSString *)[filenames objectAtIndex:i];
        int i;
        BOOL kittenUsing = NO;
        for(i = 0; i < [kittens count]; i++) {
            NSString *resolvedLogfile = [consoleView resolveFileName:filename];
            if([resolvedLogfile isEqualToString:filename]) {
                kittenUsing = YES;
                logDebug(@"kittenUsing = %d",kittenUsing);
                break;
            } 
        }
        if(!kittenUsing) {
            logDebug(@"destroying console server:%@",filename);
            [consoleView destroyServer:filename];    
        }
    }
}

- (void) _saveKittensToDefaults {
    logDebug(@"_saveKittensToDefaults");
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSData *kittensAsData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:kittens]];
    [defs setObject:kittensAsData forKey:TCSUserDefaultsKittens];
    [defs setInteger:[kittyController selectionIndex] forKey:TCSUserDefaultsSelectedKitty];
}


/*
 * If you run this in a new thread and it spawns a console server
 * in another new thread, the console server will just die silently.
 * Not sure why this is.
 */
 - (void) _updateKittyProcesses {
    @try {
        logDebug(@"Looking for kitty processes");
        NSArray *javaProcesses = [TCSProcess processesForCommand:@"java"];
        logTrace(@"processesForCommand:java = %@",javaProcesses);
        if(javaProcesses != nil) {
            int i, jcount = [javaProcesses count];
            for (i = 0; i < jcount; i++) {
                TCSProcess *process = [javaProcesses objectAtIndex:i];
                //maybe this isn't tomcat, check main class
                if(![[process arguments] containsObject:@"org.apache.catalina.startup.Bootstrap"])
                    continue;
                logTrace(@"Creating kitty from found process (%d)",[process processIdentifier]);
                TCSKitty *tk = [wrangler newKittyFromProcess:process];
                logTrace(@"Investigating status of kitty (%@) from found process (%@)",tk,process);
                if(![kittens containsObject:tk]) {
                    //kitten is running, but we've not seen it
                    logDebug(@"Found a new kitten, adding it");
                    [wrangler configureKittyWithServerConfig:tk]; //only parse if we're adding it
                    [kittyController addObject:tk];
                } else {
                    //update known kitty
                    logTrace(@"Updating kitty with process I found");
                    int idx = [kittens indexOfObject:tk];
                    tk = [kittens objectAtIndex:idx];
                    if(![[tk process] isEqual:process])
                        [tk setProcess:process];
                }
            }
        } 
    } @catch (NSException *e) {
        logError(@"Error creating kitties from java processes (%@)",[e description]);
    }
    
    @try {
        logDebug(@"Checking for dead kitties");
        int k, kcount = [kittens count];
        for(k = 0; k < kcount; k++) {
            TCSKitty *tk = [kittens objectAtIndex:k];
            [wrangler validateKittyProcess:tk];
        }  
    } @catch (NSException * e) {
        logError(@"Error validating kitty processes (%@)",[e description]);
    }
}

- (void) _setShadowNames {
    // see if there are duplicate names
    NSMutableDictionary *names = [[[NSMutableDictionary alloc] init] autorelease];
    int i, count = [kittens count];
    for (i = 0; i < count; i++) {
        TCSKitty *tk = [kittens objectAtIndex:i];
        NSString *name = [tk name];
        NSMutableArray *named = (NSMutableArray *)[names objectForKey:name];
        if(named==nil) {
            named = [[[NSMutableArray alloc] init] autorelease];
            [names setObject:named forKey:name];
        }
        [named addObject:tk];
    }
    // if there are loop through them and assign shadow names
    NSArray *nameKeys = [names allKeys];
    int j, jcount = [nameKeys count];
    for (j = 0; j < jcount; j++) { 
        NSString *name = [nameKeys objectAtIndex:j];
        NSMutableArray *named = (NSMutableArray *)[names objectForKey:name];
        int k, kcount = [named count];
        for (k = 0; k < kcount; k++) {
            TCSKitty *tk = [named objectAtIndex:k];
            NSString *shadowName = nil;
            if(kcount > 1) {
                shadowName = 
                    [NSString stringWithFormat:@"%@ (%d)",[tk name],(k+1)];
            }
            [tk setShadowName:shadowName];
        }
    }
}

- (void) _validateSystemBootForKitty:(TCSKitty *)tk {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![TCSLaunchDaemonManager didInstallACLs]) {
        logDebug(@"need to set ACLs");
        if([defaults boolForKey:TCSUserDefaultsShouldAskAboutSettingACLs]) {
            // get user permission to set ACL's
            logDebug(@"ask user if we can set ACLs");
            [appController askUserIfWeCanInstallACLs:self];
            BOOL okToInstall = 
                [[TCSPrefController sharedPrefController] canUseAccessControlLists];
            if(okToInstall) {
                @try {
                    [launchDaemonManager installACLs];
                    [defaults setBool:YES forKey:TCSUserDefaultsDidSetACLs];
                } @catch (NSException * e) {
                    [self _timedRevertStartup];
                    [appController warnUserThatEnablingACLsFailed:self];
                    return;
                }
                [launchDaemonManager setAutomaticStartupTypeForKitty:tk];
                // no more change notices for this value
                [tk set_automaticStartupType:[tk automaticStartupType]];
            } else {
                // set startup type back to old value 
                [self _timedRevertStartup];
            }
        } else if(![[TCSPrefController sharedPrefController] canUseAccessControlLists]) {
            [self _timedRevertStartup];
            [appController warnUserTheyCantUseSystemDaemons:self];
        } else {
            @try {
                [launchDaemonManager installACLs];
                [defaults setBool:YES forKey:TCSUserDefaultsDidSetACLs];
            } @catch (NSException * e) {
                //warn user that you are backing out
                [self _timedRevertStartup];
                [appController warnUserThatEnablingACLsFailed:self];
                return;
            }
            [launchDaemonManager setAutomaticStartupTypeForKitty:tk];
        }
    } else {
        [launchDaemonManager setAutomaticStartupTypeForKitty:tk];
    }
}

/**
 * This is whacked, but you can't do anything to change an observed value while 
 * you're in the middle of handling a change or the controller gets all messed
 * up.
 */
- (void) _timedRevertStartup {
    logDebug(@"_timedRevertStartup");
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self 
                                   selector:@selector(_revertStartup) 
                                   userInfo:nil 
                                    repeats:NO];
}

- (void) _revertStartup {
    logDebug(@"_revertStartup");
    //id old = [kittyController valueForKeyPath:@"selection._automaticStartupType"];
    //[kittyController setValue:old forKeyPath:@"selection.automaticStartupType"]; 
    @try {
        TCSKitty *tk = [self selectedKitty];
        [tk setAutomaticStartupType:[tk _automaticStartupType]];
    } @catch (NSException * e) {
        logError(@"Error reverting startup type: %@ (%@)",e,[e userInfo]);
    }
    logDebug(@"done");
}


/**
* This is whacked, but you can't do anything to change an observed value while 
 * you're in the middle of handling a change or the controller gets all messed
 * up.
 */
- (void) _timedRevertRunPrivileged {
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self 
                                   selector:@selector(_revertRunPrivileged) 
                                   userInfo:nil 
                                    repeats:NO];
}

- (void) _revertRunPrivileged {
    logDebug(@"_revertRunPrivileged");
    @try {
        TCSKitty *tk = [self selectedKitty];
        [tk setRunPrivileged:[tk _runPrivileged]];
    } @catch (NSException * e) {
        logError(@"Error reverting run privileged: %@ (%@)",e,[e userInfo]);
    }
    logDebug(@"done");
}



@end

