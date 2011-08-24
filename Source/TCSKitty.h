//
//  TCSKitty.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/21/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSComponent.h"

@class TCSProcess;
@class TCSConnectorComponent;
@class TCSHostComponent;


@interface TCSKitty : TCSComponent <NSCoding> {
    //user defined
    NSString *shadowName;
    BOOL useDefaults;
    BOOL runPrivileged;
    NSString *startCommand;
    TCSAutomaticStartupType automaticStartupType;

    //bootstrapped from config file
    NSString *shutdownPort;
    NSString *defaultHttpPort;
    NSString *defaultAjpPort;
    
    //env
    NSString *javaHome;
    NSString *catalinaHome;
    NSString *catalinaBase;
    NSString *catalinaOpts;
    NSString *jpdaTransport;
    NSString *jpdaAddress;
    
    // runtime info
    TCSProcess *process;
    NSArray *validationErrors;
    
    NSString *version;
    NSString *osName;
    NSString *osVersion;
    NSString *osArch;
    NSString *jvmVersion;
    NSString *jvmVendor;
    
    NSString *freeMemory;
    NSString *totalMemory;
    NSString *maxMemory;
    
    @private
    NSString *_javaHome;
    NSString *_catalinaHome;
    NSString *_catalinaBase;
    NSString *_catalinaOpts;
    BOOL _runPrivileged;
    TCSAutomaticStartupType _automaticStartupType;
    NSString *_name;
}


- (id) initWithHome:(NSString *)aHome;
- (id) initWithHome:(NSString *)aHome base:(NSString *)aBase;
+ (id) withHome:(NSString *)aHome;
+ (id) withHome:(NSString *)aHome base:(NSString *)aBase;

- (void)setName:(NSString *)newName;
- (NSString *)shadowName;
- (void)setShadowName:(NSString *)newShadowName;
- (BOOL)useDefaults;
- (void)setUseDefaults:(BOOL)newUseDefaults;
- (BOOL)runPrivileged;
- (void)setRunPrivileged:(BOOL)newRunPrivileged;
- (NSString *)shutdownPort;
- (void)setShutdownPort:(NSString *)newShutdownPort;
- (NSString *)defaultHttpPort;
- (void)setDefaultHttpPort:(NSString *)newDefaultHttpPort;
- (NSString *)defaultAjpPort;
- (void)setDefaultAjpPort:(NSString *)newDefaultAjpPort;
- (NSString *)startCommand;
- (void)setStartCommand:(NSString *)newStartCommand;
- (TCSAutomaticStartupType)automaticStartupType;
- (void)setAutomaticStartupType:(TCSAutomaticStartupType)newAutomaticStartupType;


- (NSString *)javaHome;
- (void)setJavaHome:(NSString *)newJavaHome;
- (NSString *)catalinaHome;
- (void)setCatalinaHome:(NSString *)newCatalinaHome;
- (NSString *)catalinaBase;
- (void)setCatalinaBase:(NSString *)newCatalinaBase;
- (NSString *)catalinaOpts;
- (void)setCatalinaOpts:(NSString *)newCatalinaOpts;
- (NSString *) catalinaPid;
- (NSString *)jpdaTransport;
- (void)setJpdaTransport:(NSString *)newJpdaTransport;
- (NSString *)jpdaAddress;
- (void)setJpdaAddress:(NSString *)newJpdaAddress;
- (NSString *) logfile;

- (BOOL)isRunning;
- (TCSProcess *) process;
- (void) setProcess:(TCSProcess *)newProcess;    
- (int)pid;
- (NSArray *)validationErrors;
- (void)setValidationErrors:(NSArray *)newValidationErrors;

- (NSString *)version;
- (void)setVersion:(NSString *)newVersion;
- (NSString *)osName;
- (void)setOsName:(NSString *)newOsName;
- (NSString *)osVersion;
- (void)setOsVersion:(NSString *)newOsVersion;
- (NSString *)osArch;
- (void)setOsArch:(NSString *)newOsArch;
- (NSString *)jvmVersion;
- (void)setJvmVersion:(NSString *)newJvmVersion;
- (NSString *)jvmVendor;
- (void)setJvmVendor:(NSString *)newJvmVendor;

- (NSString *)freeMemory;
- (void)setFreeMemory:(NSString *)newFreeMemory;
- (NSString *)totalMemory;
- (void)setTotalMemory:(NSString *)newTotalMemory;
- (NSString *)maxMemory;
- (void)setMaxMemory:(NSString *)newMaxMemory;

- (NSString *)_javaHome;
- (void)set_javaHome:(NSString *)new_javaHome;
- (NSString *)_catalinaHome;
- (void)set_catalinaHome:(NSString *)new_catalinaHome;
- (NSString *)_catalinaBase;
- (void)set_catalinaBase:(NSString *)new_catalinaBase;
- (NSString *)_catalinaOpts;
- (void)set_catalinaOpts:(NSString *)new_catalinaOpts;
- (BOOL)_runPrivileged;
- (void)set_runPrivileged:(BOOL)new_runPrivileged;
- (TCSAutomaticStartupType)_automaticStartupType;
- (void)set_automaticStartupType:(TCSAutomaticStartupType)new_automaticStartupType;
- (NSString *)_name;
- (void)set_name:(NSString *)new_name;

- (BOOL) javaHomeChanged;
- (BOOL) catalinaHomeChanged;
- (BOOL) catalinaBaseChanged;
- (BOOL) catalinaOptsChanged;
- (BOOL) runPrivilegedChanged;
- (BOOL) automaticStartupTypeChanged;
- (BOOL) nameChanged;

@end
