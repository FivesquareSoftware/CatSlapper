//
//  TCSCatWrangler.m
//  TomcatSlapper
//
//  Created by John Clayton on 10/30/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSCatWrangler.h"
#import "TCSKitty.h"
#import "TCSKittyParsing.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSPrefController.h"
#import "TCSServerConfigError.h"
#import "TCSComponent.h"
#import "TCSConnectorComponent.h"
#import "TCSTomcatManagerProxy.h"
#import "TCSProcess.h"

@implementation TCSCatWrangler


- (void) validateKittyProcess:(TCSKitty *)tk {
    logDebug(@"validateKittyProcess:%@",tk);
    TCSProcess *process = [TCSProcess processForProcessIdentifier:[tk pid]];
    //can be nil
    if(![[tk process] isEqual:process]) {
        [tk setProcess:process];
    }
}

- (TCSKitty *) newKittyFromProcess:(TCSProcess *)process {
    logDebug(@"newKittyFromProcess:%d",[process processIdentifier]);
    logTrace(@"process.arguments = %@",[process arguments]);
    logTrace(@"process.fullCommand = %@",[process fullCommand]);
    NSMutableDictionary *env = [[[process environment] mutableCopy] autorelease];
    //TODO only do this if we have to
    [env addEntriesFromDictionary:
            [self extractProcessEnvironmentFromArgs:[process arguments]]];
    
    logTrace(@"environment = %@",env);
    
    NSString *catalinaHome = ([env objectForKey:TCSEnvKeyCatalinaHome] != nil
                              ? [env objectForKey:TCSEnvKeyCatalinaHome]
                              : [env objectForKey:@"catalina.home"]);    
    NSString *catalinaBase = ([env objectForKey:TCSEnvKeyCatalinaBase] != nil
                              ? [env objectForKey:TCSEnvKeyCatalinaBase]
                              : [env objectForKey:@"catalina.base"]);
    NSString *javaHome = ([env objectForKey:TCSEnvKeyJavaHome] != nil
                              ? [env objectForKey:TCSEnvKeyJavaHome]
                              : [self javaHomeFromJavaCommand:[process fullCommand]]
                          );
    NSString *catalinaOpts = ([env objectForKey:TCSEnvKeyCatalinaOpts] != nil
                          ? [env objectForKey:TCSEnvKeyCatalinaOpts]
                          : [env objectForKey:@"catalina.opts"]);
    
    TCSKitty *tk = [TCSKitty withHome:catalinaHome base:catalinaBase];
    logTrace(@"[tk catalinaHome] =  %@",[tk catalinaHome]);
    logTrace(@"[tk catalinaBase] =  %@",[tk catalinaBase]);
    logTrace(@"[tk javaHome] =  %@",[tk javaHome]);
    logTrace(@"[tk catalinaOpts] =  %@",[tk catalinaOpts]);
    
    [tk setJavaHome:javaHome];
    [tk setCatalinaOpts:catalinaOpts];
    [tk setUseDefaults:NO];
    [tk setName:(catalinaBase != nil ? catalinaBase : catalinaHome)];
    [tk setProcess:process];    
    return tk;
}

- (NSString *) javaHomeFromJavaCommand:(NSString *)command {
    logTrace(@"javaHomeFromJavaCommand:%@",command);
    NSScanner *scanner = [NSScanner scannerWithString:command];
    [scanner setCaseSensitive:YES];
    NSString *javaHome = nil;
    NSString *javaCommand = nil;
    if([command rangeOfString:@"/bin/java"].location != NSNotFound) {
        BOOL found = 
            [scanner scanUpToString:@"/bin/java" intoString:&javaHome];
    } 
    logTrace(@"javaHome = '%@'",javaHome);
    return javaHome;
}

- (NSDictionary *) extractProcessEnvironmentFromArgs:(NSArray *)args {
    logTrace(@"extractProcessEnvironmentFromArgs:%@",args);
    NSMutableDictionary *env = [[NSMutableDictionary alloc] init];
    int i;
    for(i = 0; i < [args count]; i++) {
        NSString *arg = [args objectAtIndex:i];
        int idx = [arg rangeOfString:@"="].location;
        if(idx != NSNotFound) {
            logTrace(@"arg = %@",arg);
            int start = ([arg rangeOfString:@"-D"].location == 0 ? 2 : 0);
            NSString *key = [arg substringWithRange:NSMakeRange(start,(idx-start))];
            NSString *value = [arg substringWithRange:NSMakeRange(idx+1,[arg length]-(idx+1))];
            logTrace( (@"(key=value),(%@=%@)"),(key),(value) );
            // THIS COULD BE BREAKING
            @try {
                [env setObject:value forKey:key];
            } @catch (NSException *e) {
                logFatal(@"Error extracting key into environment: %@",[e description]);
            } 
        }
    }
    return [env autorelease];
}

- (void) configureKittyWithServerConfig:(TCSKitty *)tk {
    logDebug(@"configureKittyWithServerConfig:%@",tk);
    NSString *configBase;
    if([tk catalinaBase] != nil && ![[tk catalinaBase] isEqualToString:@""]) {
        logDebug(@"using catalinaBase");
        configBase = [tk catalinaBase];
    } else {
        configBase = [tk catalinaHome];
    }
    logDebug(@"configBase = %@",configBase);
    TCSConnectorComponent *defaultConnector = nil;
    if(configBase != nil) {
        NSString *configFilePath = [configBase stringByAppendingPathComponent:TCSServerConfigFile];
        configFilePath = [configFilePath stringByExpandingTildeInPath];
        configFilePath = [configFilePath stringByResolvingSymlinksInPath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:configFilePath])
            return;
        
        NSURL *configFileURL = [NSURL fileURLWithPath:configFilePath];
        logDebug(@"configFileURL = %@",configFileURL);
        NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:configFileURL];
        
        TCSKittyParsing *delegate = [TCSKittyParsing withKitty:tk];
        [parser setDelegate:delegate];
        if(![parser parse]) {
            logError(@"error parsing server config file (%@)",[parser parserError]);
            return;
        }
        
        NSMutableArray *connectors = [delegate connectors];
        int i;
        for(i = 0; i < [connectors count]; i++) {
            TCSConnectorComponent *connector = [connectors objectAtIndex:i];
            NSString *protocol = [connector protocol];
            if(protocol == nil || [protocol rangeOfString:@"HTTP"].location != NSNotFound) {
                if(defaultConnector != nil) {
                    if([defaultConnector isSecure] && ![connector isSecure]) {
                        defaultConnector = connector;
                        continue;
                    }
                    if([[defaultConnector scheme] isEqualToString:@"https"]
                       && [[connector scheme] isEqualToString:@"http"] ) {
                        defaultConnector = connector;
                        continue;
                    }
                } else {
                    defaultConnector = connector;
                }
            }
        }
    }
    logDebug(@"defaultConnector.port = %@",[defaultConnector port]);
    [tk setDefaultHttpPort:[defaultConnector port]];
}

- (void) validateKitty:(TCSKitty *)tk inKittens:(NSMutableArray *)kittens {
    logDebug(@"validateKitty:%@",tk);
    NSMutableArray *errors = [NSMutableArray array];
    
    //BOOL useDefaults = [tk useDefaults];
    TCSPrefController *defs = [TCSPrefController sharedPrefController];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;

    /*
    NSString *catalinaHome = useDefaults ? [defs catalinaHome] : [tk catalinaHome];
    NSString *catalinaBase = useDefaults ? [defs catalinaBase] : [tk catalinaBase];
    NSString *javaHome = useDefaults ? [defs javaHome] : [tk javaHome];
    */
    NSString *catalinaHome = [tk catalinaHome];
    NSString *catalinaBase = [tk catalinaBase];
    NSString *javaHome = [tk javaHome];
    NSString *errMsg;

    logDebug(@"Validating catalinaHome: %@",catalinaHome);
    logDebug(@"Validating catalinaBase: %@",catalinaBase);
    logDebug(@"Validating javaHome: %@",javaHome);
    
    //if catalina_home not set or does not contain some key files
    if(catalinaHome == nil || ([catalinaHome isEqualToString:@""])) {
        [errors addObject: [TCSServerConfigError 
                            errorForKey:@"TCSKitty.validationMessage.noCatHome" 
                                  value:catalinaHome]
        ];
    } else if(catalinaHome != nil  && ![catalinaHome isEqualToString:@""]) {
        NSString *startupScript = [catalinaHome stringByAppendingPathComponent:TCSServerStartupScript];
        NSString *bootstrapJar = [catalinaHome stringByAppendingPathComponent:TCSTomcatBootstrapJar];
        NSString *serverConf = [catalinaHome stringByAppendingPathComponent:TCSServerConfigFile];
        if (![fm fileExistsAtPath:catalinaHome isDirectory:&isDir] 
            || !isDir
            || ![fm fileExistsAtPath:startupScript]
            || ![fm fileExistsAtPath:bootstrapJar]
            || ( (catalinaBase == nil && [catalinaBase isEqualToString:@""]) 
                 && ![fm fileExistsAtPath:serverConf]) ) {
            [errors addObject: [TCSServerConfigError 
                                errorForKey:@"TCSKitty.validationMessage.catHomeNotValidCatHome"
                                      value:catalinaHome]
            ];
        }
    }
    
    //validate base, if set, must exist
    //TODO check for server.xml
    if(catalinaBase != nil && ![catalinaBase isEqualToString:@""]) {
        NSString *serverConf = [catalinaBase stringByAppendingPathComponent:TCSServerConfigFile];
        if( ![fm fileExistsAtPath:catalinaBase isDirectory:&isDir] 
            || !isDir
            || ![fm fileExistsAtPath:serverConf] ) {
            [errors addObject: [TCSServerConfigError 
                            errorForKey:@"TCSKitty.validationMessage.catBaseNotDir" 
                                  value:catalinaBase]
                ];
        }
    }
    
    //validate JAVA_HOME
    if(javaHome != nil && ![javaHome isEqualToString:@""]) {
        NSString *javaJRE = [javaHome stringByAppendingPathComponent:TCSJavaJRE];
        if(![fm fileExistsAtPath:javaHome isDirectory:&isDir] 
           || !isDir
           || ![fm fileExistsAtPath:javaJRE]) {
            [errors addObject: [TCSServerConfigError 
                                errorForKey:@"TCSKitty.validationMessage.javaHomeNotDir" 
                                      value:javaHome]
            ];
        }
    }

    //without a default port we cannot analyze components, but no catalinaHome is a cause
    logDebug(@"tk.defaultHttpPort = %@",[tk defaultHttpPort]);
    if((catalinaHome != nil || catalinaBase != nil) && 
       ([tk defaultHttpPort] == nil || [[tk defaultHttpPort] isEqualToString:@""])) {
        [errors addObject: [TCSServerConfigError 
                            errorForKey:@"TCSKitty.validationMessage.noDefaultHttpPort" 
                                  value:nil]
        ];
    }

    //look for conflicts over server.xml
    NSMutableArray *dupes = [NSMutableArray array];
    int i;
    for(i = 0; i < [kittens count]; i++) {
        TCSKitty *oKitty = [kittens objectAtIndex:i];
        if([tk isEqual:oKitty]) [dupes addObject: [oKitty name]];
    }
    if([dupes count] > 1) { // at least one besides me
        [errors addObject: [TCSServerConfigError 
                            errorForKey:@"TCSKitty.validationMessage.duplicates" 
                                  value:dupes]
        ];
    } 
    
    //TODO: we could also look at other info that might be relevant:
    // - do two servers have the same connector ports defined?
    // - etc.

    
    //logDebug(@"errors = %@",errors);
    [tk setValue:(([errors count] > 0) ? errors : nil) forKey:@"validationErrors"];
}

@end
