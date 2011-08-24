//
//  TCSAppComponent.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/14/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSComponent.h"
#import "TCSConstants.h"

@class TCSHostComponent;

@interface TCSAppComponent : TCSComponent {
    NSString *fullPath;
    NSString *docBase;
//    NSString *path;
    NSString *startupTime;
    NSString *state;
    NSString *workDir;
    
    NSString *maxActiveSessions;
    NSString *maxInactiveInterval;
    NSString *activeSessions;
    NSString *sessionCounter;
    NSString *maxActive;
    NSString *rejectedSessions;
    NSString *expiredSessions;
    NSString *processingTime;
    NSString *duplicates;
    NSString *deploymentDescriptor;
     
}


- (TCSHostComponent *) host;

- (NSString *)fullPath;
- (void)setFullPath:(NSString *)newFullPath;
- (NSString *)docBase;
- (void)setDocBase:(NSString *)newDocBase;
- (NSString *)path;
//- (void)setPath:(NSString *)newPath;
- (NSString *)startupTime;
- (void)setStartupTime:(NSString *)newStartupTime;
- (NSString *)state;
- (void)setState:(NSString *)newState;
- (NSString *)workDir;
- (void)setWorkDir:(NSString *)newWorkDir;

- (NSString *)maxActiveSessions;
- (void)setMaxActiveSessions:(NSString *)newMaxActiveSessions;
- (NSString *)maxInactiveInterval;
- (void)setMaxInactiveInterval:(NSString *)newMaxInactiveInterval;
- (NSString *)activeSessions;
- (void)setActiveSessions:(NSString *)newActiveSessions;
- (NSString *)sessionCounter;
- (void)setSessionCounter:(NSString *)newSessionCounter;
- (NSString *)maxActive;
- (void)setMaxActive:(NSString *)newMaxActive;
- (NSString *)rejectedSessions;
- (void)setRejectedSessions:(NSString *)newRejectedSessions;
- (NSString *)expiredSessions;
- (void)setExpiredSessions:(NSString *)newExpiredSessions;
- (NSString *)processingTime;
- (void)setProcessingTime:(NSString *)newProcessingTime;
- (NSString *)duplicates;
- (void)setDuplicates:(NSString *)newDuplicates;
- (NSString *)deploymentDescriptor;
- (void)setDeploymentDescriptor:(NSString *)newDeploymentDescriptor;


@end
