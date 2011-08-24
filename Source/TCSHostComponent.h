//
//  TCSHostComponent.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/14/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSComponent.h"

@interface TCSHostComponent : TCSComponent {
    NSString *appBase;
    NSString *autoDeploy;
    NSString *debug;
    NSString *deployOnStartup;
    NSString *deployXML;
    NSString *unpackWARs;
    NSString *xmlNamespaceAware;
    NSString *xmlValidation;
}

- (NSString *)appBase;
- (void)setAppBase:(NSString *)newAppBase;
- (NSString *)autoDeploy;
- (void)setAutoDeploy:(NSString *)newAutoDeploy;
- (NSString *)debug;
- (void)setDebug:(NSString *)newDebug;
- (NSString *)deployOnStartup;
- (void)setDeployOnStartup:(NSString *)newDeployOnStartup;
- (NSString *)deployXML;
- (void)setDeployXML:(NSString *)newDeployXML;
- (NSString *)unpackWARs;
- (void)setUnpackWARs:(NSString *)newUnpackWARs;
- (NSString *)xmlNamespaceAware;
- (void)setXmlNamespaceAware:(NSString *)newXmlNamespaceAware;
- (NSString *)xmlValidation;
- (void)setXmlValidation:(NSString *)newXmlValidation;


@end
