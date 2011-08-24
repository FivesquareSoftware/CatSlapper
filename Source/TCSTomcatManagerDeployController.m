//
//  TCSTomcatManagerDeployController.m
//  TomcatSlapper
//
//  Created by John Clayton on 6/15/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSTomcatManagerDeployController.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSHostComponent.h"
#import "TCSKitty.h"

@implementation TCSTomcatManagerDeployController

static TCSTomcatManagerDeployController *controller;
static NSString *applicationRemoteDeploymentPath = @"/manager/deploy?war=";
static NSString *applicationLocalDeploymentPath = @"/manager/deploy?war=";


// OBJECT STUFF ============================================================= //

+ (void) initialize {
    [self setKeys:[NSArray arrayWithObject:@"deployWarLocalFileURL"] 
            triggerChangeNotificationsForDependentKey:@"deployWarFileName"];
}

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super init]) {
        request = nil;
    }
    return self;
}

- (void) dealloc {
    [request release];
    [host release];
    [deployWarLocalFileURL release];
    [super dealloc];
}


// SINGLETON DEPLOY CONTROLLER ============================================== //

+ (TCSTomcatManagerDeployController *) sharedDeployController {
    if(controller == nil) {
        controller = [[TCSTomcatManagerDeployController alloc] _init];
        [NSBundle loadNibNamed:@"Deployer" owner:controller];
    }
    return controller;
}


// DEPLOY =================================================================== //

- (NSURLRequest *) deploymentRequestToHost:(TCSHostComponent *)aHost {
    [self setHost:aHost];
    
    [self setUrlString:[NSMutableString stringWithString:@"http://"]];
    [urlString appendString:[host name]];
    [urlString appendString:@":"];
    [urlString appendString:[(TCSKitty *)[host parent] defaultHttpPort]];
    [urlString appendString:@"/manager/deploy"];
    
    [NSApp beginSheet: deployPanel
       modalForWindow: [NSApp mainWindow]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil]; 
    [NSApp runModalForWindow:deployPanel]; //no other activity
                                          // Sheet is up here
    logDebug(@"returning request: %@",request);
    return request;
}


- (IBAction) createRemoteDeploymentRequest:(id)sender {
    logDebug(@"createRemoteDeploymentRequest:");
    [self _stopSheet];
    //set request
    //http://localhost:8080/manager/deploy?war=foo
    //http://localhost:8080/manager/deploy?path=/bartoo&war=bar.war
    //http://localhost:8080/manager/deploy?config=file:/path/context.xml
    //http://localhost:8080/manager/html/deploy?deployPath=%2Fwebdav&deployConfig=&deployWar=file%3A%2FLibrary%2FTomcat%2FMyTestCat4%2Fwebapps%2Fwebdav
    NSMutableString *qString = [NSMutableString stringWithString:@"?"];
    if(deployContextPath != nil) {
        [qString appendString:@"path="];
        [qString appendString:deployContextPath];
    }
    if(deployConfigFileURL) {
        if([qString length] > 1) [qString appendString:@"&"];
        [qString appendString:@"config="];
        [qString appendString:deployConfigFileURL];
    }
    if(deployWarURL != nil) {
        if([qString length] > 1) [qString appendString:@"&"];
        [qString appendString:@"war="];
        [qString appendString:deployWarURL];
    }
    if([qString length] > 1) [urlString appendString:qString];
    NSURL *url = [NSURL URLWithString:urlString]; 
    [self setRequest:[NSURLRequest requestWithURL:url
                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                     timeoutInterval:MANAGER_REQUEST_TIMEOUT]];        
}

- (IBAction) createLocalDeploymentRequest:(id)sender {
    logDebug(@"createLocalDeploymentRequest:");
    [self _stopSheet];
    //set request
    //http://localhost:8080/manager/deploy?path=/footoo
    logDebug(@"deployWarLocalFileURL=%@",deployWarLocalFileURL);
    NSData *warData = [NSData dataWithContentsOfURL:deployWarLocalFileURL];
//    logDebug(@"warData = %@",warData);
    logDebug(@"deployWarFileName=%@",[self deployWarFileName]);
    logDebug(@"path=%@",[[self deployWarFileName] stringByDeletingPathExtension]);

    NSMutableString *qString = [NSMutableString stringWithString:@"?"];
    [qString appendString:@"path=/"];
    [qString appendString:[[self deployWarFileName] stringByDeletingPathExtension]];
    [urlString appendString:qString];
  
    NSURL *url = [NSURL URLWithString:urlString]; 
    NSMutableURLRequest *myRequest = 
        [NSMutableURLRequest requestWithURL:url
                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                            timeoutInterval:MANAGER_REQUEST_TIMEOUT];  
    [myRequest setHTTPMethod:@"PUT"];
    [myRequest setHTTPBody:warData];
    [self setRequest:myRequest];
}

- (IBAction) cancelDeployment:(id)sender {
    [self _stopSheet];
    logDebug(@"cancelDeployment:");
}

- (IBAction) browse:(id)sender {    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op setAllowsMultipleSelection:NO];
    [op  beginSheetForDirectory:nil
                           file:nil
                          types:[NSArray arrayWithObject:@"war"]
                 modalForWindow:deployPanel
                  modalDelegate:self
                 didEndSelector:@selector(browseDidEnd:returnCode:contextInfo:)
                    contextInfo:nil
        ];
}

- (void) browseDidEnd:(NSOpenPanel *)sheet 
           returnCode:(int)returnCode 
          contextInfo:(void  *)contextInfo {
    //user cancelled
    if(returnCode != NSOKButton) return;
    logDebug(@"sheet.filenames = %@",[sheet filenames]);    
    [self setDeployWarLocalFileURL:
        [NSURL fileURLWithPath:[[sheet filenames] objectAtIndex:0]]];
}

- (void) _stopSheet {
    logDebug(@"_stopSheet");
    [NSApp endSheet:deployPanel];
    [deployPanel orderOut:self];
    [NSApp stopModal];    
    logDebug(@"_stopSheet");
}

// HELP ACTIONS ============================================================= //

- (IBAction) displayDeployHelp:(id)sender {
    [[NSHelpManager sharedHelpManager] 
            openHelpAnchor:TCSCatSlapperHelpDeployAnchor 
                    inBook:TCSCatSlapperHelpBook];
}



// KVC ======================================================================= //

- (NSURLRequest *)request {
    return request;
}

- (void)setRequest:(NSURLRequest *)newRequest {
    [newRequest retain];
    [request release];
    request = newRequest;
}

- (TCSHostComponent *)host {
    return host;
}

- (void)setHost:(TCSHostComponent *)newHost {
    [newHost retain];
    [host release];
    host = newHost;
}

- (NSMutableString *)urlString {
    return urlString;
}

- (void)setUrlString:(NSMutableString *)newUrlString {
    [newUrlString retain];
    [urlString release];
    urlString = newUrlString;
}

- (NSString *)deployContextPath {
    return deployContextPath;
}

- (void)setDeployContextPath:(NSString *)newDeployContextPath {
    [newDeployContextPath retain];
    [deployContextPath release];
    deployContextPath = newDeployContextPath;
}

- (NSString *)deployConfigFileURL {
    return deployConfigFileURL;
}

- (void)setDeployConfigFileURL:(NSString *)newDeployConfigFileURL {
    [newDeployConfigFileURL retain];
    [deployConfigFileURL release];
    deployConfigFileURL = newDeployConfigFileURL;
}

- (NSString *)deployWarURL {
    return deployWarURL;
}

- (void)setDeployWarURL:(NSString *)newDeployWarURL {
    [newDeployWarURL retain];
    [deployWarURL release];
    deployWarURL = newDeployWarURL;
}

- (NSURL *)deployWarLocalFileURL {
    return deployWarLocalFileURL;
}

- (void)setDeployWarLocalFileURL:(NSURL *)newDeployWarLocalFileURL {
    [newDeployWarLocalFileURL retain];
    [deployWarLocalFileURL release];
    deployWarLocalFileURL = newDeployWarLocalFileURL;
}

- (NSString *)deployWarFileName {
    return [[deployWarLocalFileURL path] lastPathComponent];
}



@end
