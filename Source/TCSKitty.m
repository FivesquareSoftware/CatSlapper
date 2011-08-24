//
//  TCSKitty.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSKitty.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSPrefController.h"
#import "TCSComponent.h"
#import "TCSConnectorComponent.h"
#import "TCSHostComponent.h"
#import "TCSProcess.h"


@implementation TCSKitty

// OBJECT STUFF ============================================================= //

#pragma mark Object Stuff

+ (void) initialize {
    //catalina
    [self setKeys:[NSArray arrayWithObjects:@"useDefaults" ,nil] 
            triggerChangeNotificationsForDependentKey:@"javaHome"];
    [self setKeys:[NSArray arrayWithObjects:@"useDefaults" ,nil] 
            triggerChangeNotificationsForDependentKey:@"catalinaHome"];
    [self setKeys:[NSArray arrayWithObjects:@"useDefaults" ,nil] 
            triggerChangeNotificationsForDependentKey:@"catalinaBase"];
    [self setKeys:[NSArray arrayWithObjects:@"useDefaults" ,nil] 
            triggerChangeNotificationsForDependentKey:@"catalinaOpts"];

    //validation
    [self setKeys:[NSArray arrayWithObject:@"validationErrors"] 
            triggerChangeNotificationsForDependentKey:@"validationMessage"];
    //process
    [self setKeys:[NSArray arrayWithObject:@"process"] 
            triggerChangeNotificationsForDependentKey:@"statusText"];
    [self setKeys:[NSArray arrayWithObject:@"process"] 
            triggerChangeNotificationsForDependentKey:@"pid"];
    [self setKeys:[NSArray arrayWithObject:@"process"] 
            triggerChangeNotificationsForDependentKey:@"isRunning"];
    //log
    [self setKeys:[NSArray arrayWithObjects:@"catalinaHome",@"catalinaBase"
                                           ,@"useDefaults" ,nil] 
            triggerChangeNotificationsForDependentKey:@"logfile"];
    //pid
    [self setKeys:[NSArray arrayWithObjects:@"catalinaHome", @"catalinaBase" ,nil] 
            triggerChangeNotificationsForDependentKey:@"catalinaPid"];
}

// called by array controller
- (id) init {
    logDebug(@"init");
    self = [self initWithHome:nil base:nil];
    useDefaults = NO;
    automaticStartupType = TCS_NEVER;
    runPrivileged = NO;
    [self setStartCommand:@"start"];
    [self setJavaHome:TCSJavaHome];
    logDebug(@"self = %@",self);
    return self;
}

- (id) initWithHome:(NSString *)aHome {
    return [self initWithHome:aHome base:nil];
}

- (id) initWithHome:(NSString *)aHome base:(NSString *)aBase {
    if(self = [super init]) {
        [self setCatalinaHome:aHome]; //for path correction
        [self setCatalinaBase:aBase]; //for path correction
        process = nil;
        command = [[NSNumber numberWithInt:0] retain];
        icon = [[NSImage imageNamed:@"Server"] retain];
    }
    return self;
}

+ (id) withHome:(NSString *)aHome {
    return [[[TCSKitty alloc] initWithHome:aHome] autorelease];
}

+ (id) withHome:(NSString *)aHome base:(NSString *)aBase {
    return [[[TCSKitty alloc] initWithHome:aHome base:aBase] autorelease];
}

- (void) dealloc {
    [shutdownPort release];
    
    [startCommand release];
    
    [javaHome release];
    [catalinaHome release];
    [catalinaBase release];
    [catalinaOpts release];
    [jpdaTransport release];
    [jpdaAddress release];
    
    [process release];
    [validationErrors release];
    
    [_javaHome release];
    [_catalinaHome release];
    [_catalinaBase release];
    [_catalinaOpts release];
    
    [super dealloc];    
}


 - (BOOL) isEqual:(id)anObject {
/*
 <TCSKitty: 0x558ccd0> { /Library/Tomcat/ToToKitty, /Library/Java/Home, /Library/Tomcat/MyKitty, /Library/Tomcat/ToToKitty,  }
 .isEqual:
 <NSKVONotifying_TCSKitty: 0x36b210> { MyKitty, /Library/Java/Home, /Library/Tomcat/MyKitty, /Library/Tomcat/MyKitty, nil } (1)
 
 */
    if(![anObject isKindOfClass:[TCSKitty class]]) return NO;
    BOOL isEqual = YES;
    if(![[self catalinaHome] isEqualToString:[anObject catalinaHome]]) isEqual = NO;
    if([self catalinaBase] != nil) {
        if([anObject catalinaBase] != nil) {
            if(![[self catalinaBase] isEqualToString:[anObject catalinaBase]] )
                isEqual = NO;
        } else {
            if(![[self catalinaBase] isEqualToString:[self catalinaHome]])
                isEqual = NO;
        }
    } else {
        if([anObject catalinaBase] != nil 
           && ![[anObject catalinaBase] isEqualToString:[anObject catalinaHome]] ) {
            isEqual = NO;
        }
    }
    logTrace(@"%@.isEqual:%@ (%d)",self,anObject,isEqual);
    return isEqual;
}

- (BOOL) isEqualTo:(id)obj {
    return [self isEqual:obj];
}

- (unsigned) hash {
    return [catalinaHome hash]+[catalinaBase hash];
}

- (NSString *) description {
    NSString *description = 
        [NSString stringWithFormat:@"%@ { name = \"%@\", javaHome = \"%@\", catalinaHome = \"%@\", catalinaBase = \"%@\", catalinaOpts = \"%@\", defaultHttpPort = \"%@\", startCommand = \"%@\" }"
            , [super description]
            , ([self name] != nil ? [self name] : @"nil")
            , ([self javaHome] != nil ? [self javaHome] : @"nil")
            , ([self catalinaHome] != nil ? [self catalinaHome] : @"nil")
            , ([self catalinaBase] != nil ? [self catalinaBase] : @"nil")
            , ([self catalinaOpts] != nil ? [self catalinaOpts] : @"nil") 
            , ([self defaultHttpPort] != nil ? [self defaultHttpPort] : @"nil") 
            , ([self startCommand] != nil ? [self startCommand] : @"nil") ];
    return description;
}


// USER DEFINED ============================================================= //

#pragma mark User Defined Options

- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)newName {    
    [newName retain];
    [self set_name:name];
    [name release];
    name = newName;
}

- (NSString *)shadowName {
    return (shadowName != nil && ![shadowName isEqualToString:@""]
            ? shadowName
            : name);
}

- (void)setShadowName:(NSString *)newShadowName {
    [newShadowName retain];
    [shadowName release];
    shadowName = newShadowName;
}

- (BOOL)useDefaults {
    return useDefaults;
}

- (void)setUseDefaults:(BOOL)newUseDefaults {
    useDefaults = newUseDefaults;
}

- (BOOL)runPrivileged {
    return runPrivileged;
}

- (void)setRunPrivileged:(BOOL)newRunPrivileged {
    [self set_runPrivileged:runPrivileged];
    runPrivileged = newRunPrivileged;
}

- (NSString *)startCommand {
    return startCommand;
}

- (void)setStartCommand:(NSString *)newStartCommand {
    [newStartCommand retain];
    [startCommand release];
    startCommand = newStartCommand;
}

- (TCSAutomaticStartupType)automaticStartupType {
    return automaticStartupType;
}

- (void)setAutomaticStartupType:(TCSAutomaticStartupType)newAutomaticStartupType {
    [self set_automaticStartupType:automaticStartupType];
    automaticStartupType = newAutomaticStartupType;
}

- (void)setAutomaticStartupTypeNumber:(NSNumber *)newAutomaticStartupTypeNumber {
    [self set_automaticStartupType:automaticStartupType];
    automaticStartupType = [newAutomaticStartupTypeNumber intValue];
}



// ENVIRONMENT ============================================================== //

#pragma mark Environment

- (NSString *)javaHome {
    return ([self useDefaults])
    ? [[TCSPrefController sharedPrefController] javaHome]
    : javaHome;
}

- (void)setJavaHome:(NSString *)newJavaHome {
    if(newJavaHome != nil)
        newJavaHome = [newJavaHome stringByExpandingTildeInPath];
    [newJavaHome retain];
    [self set_javaHome:javaHome];
    [javaHome release];
    javaHome = newJavaHome;
}

- (NSString *)catalinaHome {
    return ([self useDefaults])
    ? [[TCSPrefController sharedPrefController] catalinaHome]
    : catalinaHome;
}

- (void)setCatalinaHome:(NSString *)newCatalinaHome {
    if(newCatalinaHome != nil)
        newCatalinaHome = [newCatalinaHome stringByExpandingTildeInPath];
    [newCatalinaHome retain];
    [self set_catalinaHome:catalinaHome];
    [catalinaHome release];
    catalinaHome = newCatalinaHome;
}

- (NSString *)catalinaBase {
    return ([self useDefaults])
    ? [[TCSPrefController sharedPrefController] catalinaBase]
    : catalinaBase;
}

- (void)setCatalinaBase:(NSString *)newCatalinaBase {
    if(newCatalinaBase != nil)
        newCatalinaBase = [newCatalinaBase stringByExpandingTildeInPath];
    [newCatalinaBase retain];
    [self set_catalinaBase:catalinaBase];
    [catalinaBase release];
    catalinaBase = newCatalinaBase;
}

- (NSString *)catalinaOpts {
    return ([self useDefaults])
    ? [[TCSPrefController sharedPrefController] catalinaOpts]
    : catalinaOpts;
}

- (void)setCatalinaOpts:(NSString *)newCatalinaOpts {
    [newCatalinaOpts retain];
    [self set_catalinaOpts:catalinaOpts];
    [catalinaOpts release];
    catalinaOpts = newCatalinaOpts;
}

- (NSString *) catalinaPid {
    NSString *pidfile = ([self catalinaBase] != nil)
    ? [[self catalinaBase] stringByAppendingString:TCSServerPidFile]
    : nil;
    if(pidfile == nil) {
        pidfile = ([self catalinaHome] != nil)
        ? [[self catalinaHome] stringByAppendingString:TCSServerPidFile]
        : nil;
    }
    return pidfile;
}

- (NSString *)jpdaTransport {
    return jpdaTransport;
}

- (void)setJpdaTransport:(NSString *)newJpdaTransport {
    [newJpdaTransport retain];
    [jpdaTransport release];
    jpdaTransport = newJpdaTransport;
}

- (NSString *)jpdaAddress {
    return jpdaAddress;
}

- (void)setJpdaAddress:(NSString *)newJpdaAddress {
    [newJpdaAddress retain];
    [jpdaAddress release];
    jpdaAddress = newJpdaAddress;
}

- (NSString *) logfile {
    NSString *logfileBase = nil;
    NSString *logfile = nil;
    if([self catalinaBase] != nil) 
        logfileBase = [self catalinaBase];
    else if([self catalinaHome] != nil)
        logfileBase = [self catalinaHome];    
    if(logfileBase != nil)
        logfile = [logfileBase stringByAppendingPathComponent:TCSServerLogFile];
    return logfile;
}



// BOOTSTRAPPED FROM CONFIG FILE ============================================ //

#pragma mark Bootstrapped From Config File

- (NSString *)shutdownPort {
    return shutdownPort;
}

- (void)setShutdownPort:(NSString *)newShutdownPort {
    [newShutdownPort retain];
    [shutdownPort release];
    shutdownPort = newShutdownPort;
}

- (NSString *)defaultHttpPort {
    return defaultHttpPort;
}

- (void)setDefaultHttpPort:(NSString *)newDefaultHttpPort {
    [newDefaultHttpPort retain];
    [defaultHttpPort release];
    defaultHttpPort = newDefaultHttpPort;
}

- (NSString *)defaultAjpPort {
    return defaultAjpPort;
}

- (void)setDefaultAjpPort:(NSString *)newDefaultAjpPort {
    [newDefaultAjpPort retain];
    [defaultAjpPort release];
    defaultAjpPort = newDefaultAjpPort;
}


// COMPONENT PROTOCOL ======================================================= //

#pragma mark TCSComponent

- (NSImage *) icon {
    return [NSImage imageNamed:@"root"];
}

// RUNTIME INFO ============================================================= //

#pragma mark Runtime Information

- (BOOL)isRunning {
    return (process != nil) ? YES : NO;
}

- (TCSProcess *) process {
    return process;
}

- (void) setProcess:(TCSProcess *)newProcess {
    [newProcess retain];
    [process release];
    process = newProcess;
}

- (int)pid {
    return (process != nil) ? [process processIdentifier] : 0 ;
}

- (NSArray *)validationErrors {
    return validationErrors;
}

- (void)setValidationErrors:(NSArray *)newValidationErrors {
    [newValidationErrors retain];
    [validationErrors release];
    validationErrors = newValidationErrors;
}

- (NSString *)version {
    return version;
}

- (void)setVersion:(NSString *)newVersion {
    [newVersion retain];
    [version release];
    version = newVersion;
}

- (NSString *)osName {
    return osName;
}

- (void)setOsName:(NSString *)newOsName {
    [newOsName retain];
    [osName release];
    osName = newOsName;
}

- (NSString *)osVersion {
    return osVersion;
}

- (void)setOsVersion:(NSString *)newOsVersion {
    [newOsVersion retain];
    [osVersion release];
    osVersion = newOsVersion;
}

- (NSString *)osArch {
    return osArch;
}

- (void)setOsArch:(NSString *)newOsArch {
    [newOsArch retain];
    [osArch release];
    osArch = newOsArch;
}

- (NSString *)jvmVersion {
    return jvmVersion;
}

- (void)setJvmVersion:(NSString *)newJvmVersion {
    [newJvmVersion retain];
    [jvmVersion release];
    jvmVersion = newJvmVersion;
}

- (NSString *)jvmVendor {
    return jvmVendor;
}

- (void)setJvmVendor:(NSString *)newJvmVendor {
    [newJvmVendor retain];
    [jvmVendor release];
    jvmVendor = newJvmVendor;
}

- (NSString *)freeMemory {
    return freeMemory;
}

- (void)setFreeMemory:(NSString *)newFreeMemory {
    [newFreeMemory retain];
    [freeMemory release];
    freeMemory = newFreeMemory;
}

- (NSString *)totalMemory {
    return totalMemory;
}

- (void)setTotalMemory:(NSString *)newTotalMemory {
    [newTotalMemory retain];
    [totalMemory release];
    totalMemory = newTotalMemory;
}

- (NSString *)maxMemory {
    return maxMemory;
}

- (void)setMaxMemory:(NSString *)newMaxMemory {
    [newMaxMemory retain];
    [maxMemory release];
    maxMemory = newMaxMemory;
}




// COMPONENT PROTOCOL ======================================================= //

#pragma mark TCSComponent

- (NSString *)statusText {
    NSString *myStatusText;
    if(process != nil) {
        int pid = [process processIdentifier];
        NSString *runningFormat = NSLocalizedString(@"TCSKitty.statusText.running",nil);
        myStatusText = [NSString stringWithFormat:runningFormat,pid,[process runningTime]];
    } else {
        myStatusText = NSLocalizedString(@"TCSKitty.statusText.stopped",nil);
    }
    return myStatusText;
}


- (NSString *) componentInfo {
    /*
     Tomcat Version: Apache Tomcat/5.0.28
     OS Name: Mac OS X
     OS Version: 10.3.8
     OS Architecture: ppc
     JVM Version: 1.4.2_05-141.4
     JVM Vendor: "Apple Computer, Inc."
     */
    NSString *infoString = @"";
    infoString = [infoString stringByAppendingFormat:@"Tomcat Version: %@",version];
    infoString = [infoString stringByAppendingFormat:@"\nOS Name: %@",osName];
    infoString = [infoString stringByAppendingFormat:@"\nOS Version: %@",osVersion];
    infoString = [infoString stringByAppendingFormat:@"\nOS Architecture: %@",osArch];
    infoString = [infoString stringByAppendingFormat:@"\nJVM Version: %@",jvmVersion];
    infoString = [infoString stringByAppendingFormat:@"\nJVM Vendor: %@",jvmVendor];
    return infoString;
}

- (NSString *)componentStatus {
    logDebug(@"%@.componentStatus:",self);
    logDebug(@"%@.freeMemory: %@",self,freeMemory);
    NSString *statusString = @"";
    statusString = 
        [statusString stringByAppendingFormat:@"Free memory: %@ MB",freeMemory];
    statusString = 
        [statusString stringByAppendingFormat:@"\nTotal memory: %@ MB",totalMemory];
    statusString = 
        [statusString stringByAppendingFormat:@"\nMax memory: %@ MB",maxMemory];
    return statusString;
}


// SHADOW METHODS =========================================================== //
// these are for storing old values for use in change notifications

#pragma mark Shadow Methods

- (NSString *)_javaHome {
    return _javaHome;
}

- (void)set_javaHome:(NSString *)new_javaHome {
    [new_javaHome retain];
    [_javaHome release];
    _javaHome = new_javaHome;
}

- (NSString *)_catalinaHome {
    return _catalinaHome;
}

- (void)set_catalinaHome:(NSString *)new_catalinaHome {
    [new_catalinaHome retain];
    [_catalinaHome release];
    _catalinaHome = new_catalinaHome;
}

- (NSString *)_catalinaBase {
    return _catalinaBase;
}

- (void)set_catalinaBase:(NSString *)new_catalinaBase {
    [new_catalinaBase retain];
    [_catalinaBase release];
    _catalinaBase = new_catalinaBase;
}

- (NSString *)_catalinaOpts {
    return _catalinaOpts;
}

- (void)set_catalinaOpts:(NSString *)new_catalinaOpts {
    [new_catalinaOpts retain];
    [_catalinaOpts release];
    _catalinaOpts = new_catalinaOpts;
}

/*
- (BOOL)_enableStartupItem {
    return _enableStartupItem;
}

- (void)set_enableStartupItem:(BOOL)new_enableStartupItem {
    _enableStartupItem = new_enableStartupItem;
}
*/
- (BOOL)_runPrivileged {
    return _runPrivileged;
}

- (void)set_runPrivileged:(BOOL)new_runPrivileged {
    _runPrivileged = new_runPrivileged;
}

- (TCSAutomaticStartupType)_automaticStartupType {
    return _automaticStartupType;
}

- (void)set_automaticStartupType:(TCSAutomaticStartupType)new_automaticStartupType {
    _automaticStartupType = new_automaticStartupType;
}

- (NSString *)_name {
    return _name;
}

- (void)set_name:(NSString *)new_name {
    [new_name retain];
    [_name release];
    _name = new_name;
}


// CHANGE METHODS =========================================================== //
#pragma mark Change methods


- (BOOL) javaHomeChanged {
    logDebug(@"javaHomeChanged:%@!=%@(%d)",javaHome,_javaHome,(![javaHome isEqualToString:_javaHome]));
    return ![javaHome isEqualToString:_javaHome];
}

- (BOOL) catalinaHomeChanged {
    logDebug(@"catalinaHomeChanged:%@!=%@(%d)",catalinaHome,_catalinaHome,(![catalinaHome isEqualToString:_catalinaHome]));
    return ![catalinaHome isEqualToString:_catalinaHome];
}

- (BOOL) catalinaBaseChanged {
    logDebug(@"catalinaBaseChanged:%@!=%@(%d)",catalinaBase,_catalinaBase,(![catalinaBase isEqualToString:_catalinaBase]));
    return ![catalinaBase isEqualToString:_catalinaBase];
}

- (BOOL) catalinaOptsChanged {
    logDebug(@"catalinaOptsChanged:%@!=%@(%d)",catalinaOpts,_catalinaOpts,(![catalinaOpts isEqualToString:_catalinaOpts]));
    return ![catalinaOpts isEqualToString:_catalinaOpts];
}

- (BOOL) runPrivilegedChanged {
    return runPrivileged != _runPrivileged;
}

- (BOOL) automaticStartupTypeChanged {
    return automaticStartupType != _automaticStartupType;
}

- (BOOL) nameChanged; {
    return ![name isEqualToString:_name];
}


// NSCoding ================================================================= //

#pragma mark NSCoding

- (void) encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:name forKey:@"TCSKittyName"];
    [coder encodeBool:useDefaults forKey:@"TCSKittyUseDefaults"];
    [coder encodeInt:automaticStartupType forKey:@"TCSKittyAutomaticStartupType"];
    [coder encodeBool:runPrivileged forKey:@"TCSKittyRunPrivileged"];
    [coder encodeObject:startCommand forKey:@"TCSKittyStartCommand"];
    
    [coder encodeObject:shutdownPort forKey:@"TCSKittyShutdownPort"];
    [coder encodeObject:defaultHttpPort forKey:@"TCSKittyDefaultHttpPort"];
    [coder encodeObject:defaultAjpPort forKey:@"TCSKittyDefaultAjpPort"];
    
    
    [coder encodeObject:javaHome forKey:@"TCSKittyJavaHome"];
    [coder encodeObject:catalinaHome forKey:@"TCSKittyCatalinaHome"];
    [coder encodeObject:catalinaBase forKey:@"TCSKittyCatalinaBase"];
    [coder encodeObject:catalinaOpts forKey:@"TCSKittyCatalinaOpts"];        
    [coder encodeObject:jpdaTransport forKey:@"TCSKittyJpdaTransport"];        
    [coder encodeObject:jpdaAddress forKey:@"TCSKittyJpdaAddress"];        
}

- (id) initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    [self setName:[coder decodeObjectForKey:@"TCSKittyName"]];
    [self setUseDefaults:[coder decodeBoolForKey:@"TCSKittyUseDefaults"]];
    [self setAutomaticStartupType:[coder decodeIntForKey:@"TCSKittyAutomaticStartupType"]];
    [self setRunPrivileged:[coder decodeBoolForKey:@"TCSKittyRunPrivileged"]];
    [self setStartCommand:[coder decodeObjectForKey:@"TCSKittyStartCommand"]];
    
    [self setShutdownPort:[coder decodeObjectForKey:@"TCSKittyShutdownPort"]];
    [self setDefaultHttpPort:[coder decodeObjectForKey:@"TCSKittyDefaultHttpPort"]];
    [self setDefaultAjpPort:[coder decodeObjectForKey:@"TCSKittyDefaultAjpPort"]];
    
    [self setJavaHome:[coder decodeObjectForKey:@"TCSKittyJavaHome"]];
    [self setCatalinaHome:[coder decodeObjectForKey:@"TCSKittyCatalinaHome"]];
    [self setCatalinaBase:[coder decodeObjectForKey:@"TCSKittyCatalinaBase"]];
    [self setCatalinaOpts:[coder decodeObjectForKey:@"TCSKittyCatalinaOpts"]];
    [self setJpdaTransport:[coder decodeObjectForKey:@"TCSKittyJpdaTransport"]];
    [self setJpdaAddress:[coder decodeObjectForKey:@"TCSKittyJpdaAddress"]];

    // init shadows to the same
    [self set_javaHome:javaHome];
    [self set_catalinaHome:catalinaHome];
    [self set_catalinaBase:catalinaBase];
    [self set_catalinaOpts:catalinaOpts];
    [self set_automaticStartupType:automaticStartupType];
    [self set_runPrivileged:runPrivileged];

    process = nil;
    
    return self;
}



@end
