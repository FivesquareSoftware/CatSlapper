//
//  TCSAppComponent.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/14/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSAppComponent.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSHostComponent.h"
@implementation TCSAppComponent

// OBJECT STUFF ============================================================= //

- (id) initWithParent:(TCSComponent *)aParent
                 name:(NSString *)aName {
    if(self = [super initWithParent:aParent name:aName]) {
        icon = [[NSImage imageNamed:@"application"] retain];
        name = [aName retain];
        fullPath = 
            [[NSString stringWithFormat:@"//%@/%@",[aParent name],aName] retain];
    }
    return self;
}

- (void) dealloc {
    [fullPath release];
    
    [docBase release];
    //[path release];
    [startupTime release];
    [state release];
    [workDir release];
    
    [maxActiveSessions release];
    [maxInactiveInterval release];
    [activeSessions release];
    [sessionCounter release];
    [maxActive release];
    [rejectedSessions release];
    [expiredSessions release];
    [processingTime release];
    [duplicates release];
    [super dealloc];
}

- (void) updateWithComponent:(TCSComponent *)aComponent {
    logTrace(@"updateWithComponent:%@",aComponent);
    [super updateWithComponent:aComponent];
    if([(NSObject *)aComponent isMemberOfClass:[TCSAppComponent class]]) {
        TCSAppComponent *myComponent = (TCSAppComponent *)aComponent;
//        if([myComponent path] != nil) [self setPath:[myComponent path]];
        if([myComponent fullPath] != nil) [self setFullPath:[myComponent fullPath]];
        if([myComponent docBase] != nil) [self setDocBase:[myComponent docBase]];
        if([myComponent startupTime] != nil) [self setStartupTime:[myComponent startupTime]];
        if([myComponent state] != nil) [self setState:[myComponent state]];
        if([myComponent workDir] != nil) [self setWorkDir:[myComponent workDir]];
        if([myComponent maxActiveSessions] != nil) [self setMaxActiveSessions:[myComponent maxActiveSessions]];
        if([myComponent maxInactiveInterval] != nil) [self setMaxInactiveInterval:[myComponent maxInactiveInterval]];
        if([myComponent activeSessions] != nil) [self setActiveSessions:[myComponent activeSessions]];
        if([myComponent sessionCounter] != nil) [self setSessionCounter:[myComponent sessionCounter]];
        if([myComponent maxActive] != nil) [self setMaxActive:[myComponent maxActive]];
        if([myComponent rejectedSessions] != nil) [self setRejectedSessions:[myComponent rejectedSessions]];
        if([myComponent expiredSessions] != nil) [self setExpiredSessions:[myComponent expiredSessions]];
        if([myComponent processingTime] != nil) [self setProcessingTime:[myComponent processingTime]];
        if([myComponent duplicates] != nil) [self setDuplicates:[myComponent duplicates]];
    }
}

- (BOOL) isEqual:(id)obj {
    if(![obj isMemberOfClass:[TCSAppComponent class]]) return NO;
    if(obj == nil) return NO;
    return ([[self fullPath] isEqualToString:[(TCSAppComponent *)obj fullPath]]);
}

- (NSString *) description {
    NSString *description = [super description];
    description = [description stringByAppendingString:[self fullPath]];
    return description;
}

// RUNTIME INFO ============================================================= //

- (NSString *) name {
    return (name == nil || [name isEqualToString:@""] ? @"ROOT" : name);
}

- (TCSHostComponent *) host {
    return (TCSHostComponent *)parent;
}

- (NSString *)fullPath {
    return fullPath;
}

- (void)setFullPath:(NSString *)newFullPath {
    [newFullPath retain];
    [fullPath release];
    fullPath = newFullPath;
}

- (NSString *)docBase {
    return docBase;
}

- (void)setDocBase:(NSString *)newDocBase {
    [newDocBase retain];
    [docBase release];
    docBase = newDocBase;
}

- (NSString *)path {
    NSString *myPath = nil;
    if(fullPath != nil) {
        NSArray *pathComponents = [fullPath pathComponents];
        if([pathComponents count] > 2) {
            logDebug(@"pathComponents = %@",pathComponents);
            NSString *path = [pathComponents objectAtIndex:[pathComponents count]-1];
            logDebug(@"path = %@",path);
            if([path isEqualToString:@"/"]) {
                myPath = path;
            } else {
                myPath = [@"/" stringByAppendingString:path];
            }
            logDebug(@"myPath = %@",myPath);
        }
    }
    return myPath;
}

- (NSString *)startupTime {
    return startupTime;
}

- (void)setStartupTime:(NSString *)newStartupTime {
    [newStartupTime retain];
    [startupTime release];
    startupTime = newStartupTime;
}

- (NSString *)state {
    return state;
}

- (void)setState:(NSString *)newState {
    [newState retain];
    [state release];
    state = newState;
}

- (NSString *)workDir {
    return workDir;
}

- (void)setWorkDir:(NSString *)newWorkDir {
    [newWorkDir retain];
    [workDir release];
    workDir = newWorkDir;
}

- (NSString *)maxActiveSessions {
    return maxActiveSessions;
}

- (void)setMaxActiveSessions:(NSString *)newMaxActiveSessions {
    [newMaxActiveSessions retain];
    [maxActiveSessions release];
    maxActiveSessions = newMaxActiveSessions;
}

- (NSString *)maxInactiveInterval {
    return maxInactiveInterval;
}

- (void)setMaxInactiveInterval:(NSString *)newMaxInactiveInterval {
    [newMaxInactiveInterval retain];
    [maxInactiveInterval release];
    maxInactiveInterval = newMaxInactiveInterval;
}

- (NSString *)activeSessions {
    return activeSessions;
}

- (void)setActiveSessions:(NSString *)newActiveSessions {
    [newActiveSessions retain];
    [activeSessions release];
    activeSessions = newActiveSessions;
}

- (NSString *)sessionCounter {
    return sessionCounter;
}

- (void)setSessionCounter:(NSString *)newSessionCounter {
    [newSessionCounter retain];
    [sessionCounter release];
    sessionCounter = newSessionCounter;
}

- (NSString *)maxActive {
    return maxActive;
}

- (void)setMaxActive:(NSString *)newMaxActive {
    [newMaxActive retain];
    [maxActive release];
    maxActive = newMaxActive;
}

- (NSString *)rejectedSessions {
    return rejectedSessions;
}

- (void)setRejectedSessions:(NSString *)newRejectedSessions {
    [newRejectedSessions retain];
    [rejectedSessions release];
    rejectedSessions = newRejectedSessions;
}

- (NSString *)expiredSessions {
    return expiredSessions;
}

- (void)setExpiredSessions:(NSString *)newExpiredSessions {
    [newExpiredSessions retain];
    [expiredSessions release];
    expiredSessions = newExpiredSessions;
}

- (NSString *)processingTime {
    return processingTime;
}

- (void)setProcessingTime:(NSString *)newProcessingTime {
    [newProcessingTime retain];
    [processingTime release];
    processingTime = newProcessingTime;
}

- (NSString *)duplicates {
    return duplicates;
}

- (void)setDuplicates:(NSString *)newDuplicates {
    [newDuplicates retain];
    [duplicates release];
    duplicates = newDuplicates;
}

- (NSString *)deploymentDescriptor {
    return deploymentDescriptor;
}

- (void)setDeploymentDescriptor:(NSString *)newDeploymentDescriptor {
    [newDeploymentDescriptor retain];
    [deploymentDescriptor release];
    deploymentDescriptor = newDeploymentDescriptor;
}




// COMPONENT PROTOCOL ======================================================= //

- (NSString *) statusText {
    NSString *statusString;
    if ([state isEqualToString:@"1"]) statusString = @"running";
    else if ([state isEqualToString:@"0"]) statusString = @"stopped";
    else statusString = @"unknown";
    return [NSString stringWithFormat:@"state: %@",statusString];
}

- (NSString *) componentInfo {
    /*
     Name: Catalina:j2eeType=WebModule,name=//localhost/ModernVictorian,J2EEApplication=none,J2EEServer=none
     docBase: /usr/local/tomcat/webapps/ModernVictorian
     path: /ModernVictorian
     startupTime: 112
     state: 1
     workDir: work/Catalina/localhost/ModernVictorian
     */
    NSString *infoString = @"";
    infoString = 
        [infoString stringByAppendingFormat:@"Name: %@",name];
    infoString = 
        [infoString stringByAppendingFormat:
            @"\ndocBase: %@",(docBase != nil ? docBase : @"")];
    infoString = 
        [infoString stringByAppendingFormat:
           @"\npath: %@",[self path]];
    infoString = 
        [infoString stringByAppendingFormat:
            @"\nstartupTime: %@",(startupTime != nil ? startupTime : @"")];
    infoString = 
        [infoString stringByAppendingFormat:
            @"\nstate: %@",(state != nil ? state : @"")];
    infoString = 
        [infoString stringByAppendingFormat:
            @"\nworkDir: %@",(workDir != nil ? workDir : @"")];
    return infoString;
}

- (NSString *)componentStatus {
    /*
     Name: Catalina:type=Manager,path=/ModernVictorian,host=localhost
     maxActiveSessions: -1
     maxInactiveInterval: 1800
     activeSessions: 0
     sessionCounter: 0
     maxActive: 0
     rejectedSessions: 0
     expiredSessions: 0
     processingTime: 6
     duplicates: 0
     */
    NSString *statusString = @"";
    statusString = 
        [statusString stringByAppendingFormat:
           @"Name: %@",(name != nil ? name : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nmaxActiveSessions: %@"
            ,(maxActiveSessions != nil ? maxActiveSessions : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nmaxInactiveInterval: %@"
            ,(maxInactiveInterval != nil ? maxInactiveInterval : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nactiveSessions: %@"
            ,(activeSessions != nil ? activeSessions : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nsessionCounter: %@"
            ,(sessionCounter != nil ? sessionCounter : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nmaxActive: %@"
            ,(maxActive != nil ? maxActive : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nrejectedSessions: %@"
            ,(rejectedSessions != nil ? rejectedSessions : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nexpiredSessions: %@"
            ,(expiredSessions != nil ? expiredSessions : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nprocessingTime: %@"
            ,(processingTime != nil ? processingTime : @"")];
    statusString = 
        [statusString stringByAppendingFormat:
            @"\nduplicates: %@"
            ,(duplicates != nil ? duplicates : @"")];
    
    return statusString;
}


// NSCoding ================================================================= //

- (void) encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[self fullPath] forKey:@"TCSFullPath"];
    [coder encodeObject:[self docBase] forKey:@"TCSDocBase"];
}

- (id) initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    fullPath = [[coder decodeObjectForKey:@"TCSFullPath"] retain];
    docBase = [[coder decodeObjectForKey:@"TCSDocBase"] retain];
    return self;
}


@end
