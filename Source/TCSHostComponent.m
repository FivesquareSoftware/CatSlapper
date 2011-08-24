//
//  TCSHostComponent.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/14/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSHostComponent.h"
#import "TCSConstants.h"


@implementation TCSHostComponent


// OBJECT STUFF ============================================================= //

- (id) initWithParent:(TCSComponent *)aParent
                 name:(NSString *)aName {
    if(self = [super initWithParent:aParent name:aName]) {
        icon = [[NSImage imageNamed:@"host"] retain];
    }
    return self;
}



// RUNTIME INFO ============================================================= //

- (BOOL) isEqual:(id)obj {
    if(![obj isMemberOfClass:[TCSHostComponent class]]) return NO;
    if(obj == nil) return NO;
    
    return ([[self name] isEqualToString:[(TCSHostComponent *)obj name]]);
}

- (NSString *) description {
    NSString *description = [super description];
    description = ([self name] != nil)
        ? [description stringByAppendingString:[self name]]
        : description;
    return description;
}


- (NSString *)appBase {
    return appBase;
}

- (void)setAppBase:(NSString *)newAppBase {
    [newAppBase retain];
    [appBase release];
    appBase = newAppBase;
}

- (NSString *)autoDeploy {
    return autoDeploy;
}

- (void)setAutoDeploy:(NSString *)newAutoDeploy {
    [newAutoDeploy retain];
    [autoDeploy release];
    autoDeploy = newAutoDeploy;
}

- (NSString *)debug {
    return debug;
}

- (void)setDebug:(NSString *)newDebug {
    [newDebug retain];
    [debug release];
    debug = newDebug;
}

- (NSString *)deployOnStartup {
    return deployOnStartup;
}

- (void)setDeployOnStartup:(NSString *)newDeployOnStartup {
    [newDeployOnStartup retain];
    [deployOnStartup release];
    deployOnStartup = newDeployOnStartup;
}

- (NSString *)deployXML {
    return deployXML;
}

- (void)setDeployXML:(NSString *)newDeployXML {
    [newDeployXML retain];
    [deployXML release];
    deployXML = newDeployXML;
}

- (NSString *)unpackWARs {
    return unpackWARs;
}

- (void)setUnpackWARs:(NSString *)newUnpackWARs {
    [newUnpackWARs retain];
    [unpackWARs release];
    unpackWARs = newUnpackWARs;
}

- (NSString *)xmlNamespaceAware {
    return xmlNamespaceAware;
}

- (void)setXmlNamespaceAware:(NSString *)newXmlNamespaceAware {
    [newXmlNamespaceAware retain];
    [xmlNamespaceAware release];
    xmlNamespaceAware = newXmlNamespaceAware;
}

- (NSString *)xmlValidation {
    return xmlValidation;
}

- (void)setXmlValidation:(NSString *)newXmlValidation {
    [newXmlValidation retain];
    [xmlValidation release];
    xmlValidation = newXmlValidation;
}



// COMPONENT PROTOCOL ======================================================= //

- (NSString *) statusText {
    NSString *myStatusText = 
    [NSString stringWithFormat:@"deployed: %d",[self numberOfComponents]];
    return myStatusText;
}

- (NSString *) componentInfo {
    /*
     Name: Catalina:type=Host,host=local.fivesquare.net
     appBase: /Users/johnclay/Sites/fivesquaresoftware.com
     autoDeploy: true
     debug: 0
     deployOnStartup: true
     deployXML: true
     unpackWARs: true
     xmlNamespaceAware: false
     xmlValidation: false
     */    
    NSString *infoString = @"";
    infoString = [infoString stringByAppendingFormat:@"Name: %@",name];
    infoString = [infoString stringByAppendingFormat:@"\nappBase: %@",appBase];
    infoString = [infoString stringByAppendingFormat:@"\nautoDeploy: %@",autoDeploy];
    infoString = [infoString stringByAppendingFormat:@"\ndebug: %@",debug];
    infoString = [infoString stringByAppendingFormat:@"\ndeployOnStartup: %@",deployOnStartup];
    infoString = [infoString stringByAppendingFormat:@"\ndeployXML: %@",deployXML];
    infoString = [infoString stringByAppendingFormat:@"\nunpackWARs: %@",unpackWARs];
    infoString = [infoString stringByAppendingFormat:@"\nxmlNamespaceAware: %@",xmlNamespaceAware];
    infoString = [infoString stringByAppendingFormat:@"\nxmlValidation: %@",xmlValidation];
    return infoString;
}

- (NSString *)componentStatus {
    return [self statusText]; //TODO can't think of any more host status
}

@end
