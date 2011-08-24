//
//  TCSTomcatManagerProxy.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/4/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSTomcatManagerProxy.h"
#import "TCSTomcatManagerProxy+Private.h"
#import "TCSKitty.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSServerInfoResponseDelegate.h"
#import "TCSServerStatusResponseDelegate.h"
#import "TCSConnectorsInfoResponseDelegate.h"
#import "TCSHostsInfoResponseDelegate.h"
#import "TCSApplicationsInfoResponseDelegate.h"
#import "TCSApplicationsStatusResponseDelegate.h"
#import "TCSApplicationStartResponseDelegate.h"
#import "TCSApplicationStopResponseDelegate.h"
#import "TCSApplicationReloadResponseDelegate.h"
#import "TCSApplicationDeployResponseDelegate.h"
#import "TCSApplicationUndeployResponseDelegate.h"
#import "TCSPrefController.h"
#import "TCSComponentViewDataSource.h"
#import "TCSHostComponent.h"
#import "TCSAppComponent.h"

@implementation TCSTomcatManagerProxy

// STATIC VARS ============================================================== //

// localhost
static NSString *serverInfoPath = @"/manager/serverinfo";
static NSString *serverStatusPath = @"/manager/status?XML=true";
static NSString *connectorsInfoPath = @"/manager/jmxproxy/?qry=*:type=Connector,*";
static NSString *hostsInfoPath = @"/manager/jmxproxy/?qry=*:type=Host,*";
static NSString *applicationsInfoPath = @"/manager/jmxproxy/?qry=*:j2eeType=WebModule,*";
static NSString *applicationsStatusPath = @"/manager/jmxproxy/?qry=*:type=Manager,*";
// each  host
//static NSString *applicationsListPath = @"/manager/list";
//static NSString *sessionsPath = @"/manager/sessions?path=";
static NSString *applicationStartPath = @"/manager/start?path=";
static NSString *applicationStopPath = @"/manager/stop?path=";
static NSString *applicationReloadPath = @"/manager/reload?path=";
static NSString *applicationUndeployPath = @"/manager/undeploy?path=";
//static NSString *applicationDeployPath = @"/manager/deploy?war=";

// OBJECT STUFF ============================================================= //

- (id) init {
    if(self = [super init]) {
        [self registerObservations];
        updatingKitty = nil;
        forced = NO;
        currentRequestConnection = nil;
    }
    return self;
}

- (void) dealloc {
    [host release];
    [currentRequestConnection release];
    [self removeObservations];
    [super dealloc];
}


// KVC ===================================================================== //

- (NSURLConnection *) currentRequestConnection {
    return currentRequestConnection;
}

- (void) setCurrentRequestConnection:(NSURLConnection *) conn {
    [conn retain];
    @synchronized(self) {
        [currentRequestConnection release];
        currentRequestConnection = conn;
    }
}


// MANAGER REQUEST STUFF ==================================================== //

- (BOOL) isUpdating {
    return (updatingKitty != nil);
}

- (BOOL) isUpdatingKitty:(TCSKitty *)tk {
    return ([updatingKitty isEqual:tk]);
}

- (IBAction) cancelCurrentRequest:(id)sender {
    logDebug(@"cancelCurrentRequest:");
    [dataSource postMessage:
        NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.requestCanceled",nil)];
    @synchronized(self) {
        [currentRequestConnection cancel];
    }
    [self _destroyRequest];
}

- (void) updateComponentsForKitty:(TCSKitty *)tk {
    logDebug(@"updateComponentsForKitty: %@",tk);
    [self updateComponentsForKitty:tk force:NO];
}

- (void) updateComponentsForKitty:(TCSKitty *)tk force:(BOOL)force {
    logDebug(@"updateComponentsForKitty:%@ force:%d",tk,force);
    //not if user doesn't want to
    if(![self _isAutomaticUpdateAndOk:force]) return;
    // one update at a time
    if(![self _initRequestForKitty:tk forced:force]) return;
    
    [dataSource postMessage:
        NSLocalizedString(
          @"TCSTomcatManagerProxy.statusMsg.startingComponentUpdate"
          ,nil)
        ];
    [self _updateServerInfo];
}

- (void) startApplication:(TCSAppComponent *)app 
                       forKitty:(TCSKitty *)tk {
    logDebug(@"startApplication:%@ forKitty:%@",app,tk);
    // one update at a time
    if(![self _initRequestForKitty:tk forced:YES]) return;

    [dataSource postFormat:
        NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.startingApplicationStart",nil)
        , [app path]];
    
    NSString *applicationStartURLString = 
        [host stringByAppendingString:applicationStartPath];
    applicationStartURLString = 
        [applicationStartURLString stringByAppendingPathComponent:[app path]];
    [self _startURLConnection:applicationStartURLString 
                     delegate:[TCSApplicationStartResponseDelegate withComponent:app]];
}

- (void) stopApplication:(TCSAppComponent *)app 
                      forKitty:(TCSKitty *)tk {
    // one update at a time
    if(![self _initRequestForKitty:tk forced:YES]) return;

    [dataSource postMessage:
        NSLocalizedString(
          @"TCSTomcatManagerProxy.statusMsg.startingApplicationStop"
          ,nil)
        ];

    NSString *applicationStopURLString = 
        [host stringByAppendingString:applicationStopPath];
    applicationStopURLString = 
        [applicationStopURLString stringByAppendingPathComponent:[app path]];
    [self _startURLConnection:applicationStopURLString 
                     delegate:[TCSApplicationStopResponseDelegate withComponent:app]];
}

- (void) reloadApplication:(TCSAppComponent *)app
                        forKitty:(TCSKitty *)tk {
    // one update at a time
    if(![self _initRequestForKitty:tk forced:YES]) return;

    [dataSource postMessage:
        NSLocalizedString(
          @"TCSTomcatManagerProxy.statusMsg.startingApplicationReload"
          ,nil)
        ];
    
    NSString *applicationReloadURLString = 
        [host stringByAppendingString:applicationReloadPath];
    applicationReloadURLString = 
        [applicationReloadURLString stringByAppendingPathComponent:[app path]];
    [self _startURLConnection:applicationReloadURLString 
                     delegate:[TCSApplicationReloadResponseDelegate withComponent:app]];
}

- (void) deploymentRequest:(NSURLRequest *) request 
                    onHost:(TCSHostComponent *)aHost
                        forKitty:(TCSKitty *)tk {
    // one update at a time
    if(![self _initRequestForKitty:tk forced:YES]) return;
    
    [dataSource postMessage:
        NSLocalizedString(
          @"TCSTomcatManagerProxy.statusMsg.startingApplicationDeploy"
          ,nil)
        ];
     [self _makeMangerRequest:request
                     delegate:[TCSApplicationDeployResponseDelegate withComponent:aHost]];
}

- (void) undeployApplication:(TCSAppComponent *)app {
    // one update at a time
    TCSKitty *tk = (TCSKitty *)[app rootComponent];
    if(![self _initRequestForKitty:tk forced:YES]) return;

    [dataSource postMessage:
        NSLocalizedString(
          @"TCSTomcatManagerProxy.statusMsg.startingApplicationUndeploy"
          ,nil)
        ];

    TCSHostComponent *appHost = [app host];
    NSString *applicationUndeployURLString = 
        [@"http://" stringByAppendingString:[appHost name]];
    applicationUndeployURLString = 
        [applicationUndeployURLString stringByAppendingString:@":"];
    applicationUndeployURLString = 
        [applicationUndeployURLString stringByAppendingString:[tk defaultHttpPort]];
    applicationUndeployURLString =
        [applicationUndeployURLString stringByAppendingString:applicationUndeployPath];
    applicationUndeployURLString = 
        [applicationUndeployURLString stringByAppendingString:[app path]];
    [self _startURLConnection:applicationUndeployURLString 
                     delegate:[TCSApplicationUndeployResponseDelegate withComponent:app]];
}


// NOTIFICATIONS ============================================================ //
#pragma mark Notifications

- (void) serverInfoUpdateReceived:(NSNotification *)notification {
    logDebug(@"serverInfoUpdateReceived:");
    //user prefs may have changed
    if([self _isAutomaticUpdateAndOk:forced])        
        [self _updateConnectorsInfo];
    else
        [self _destroyRequest];
}

- (void) connectorsInfoUpdateReceived:(NSNotification *)notification {
    logDebug(@"connectorsInfoUpdateReceived:");
    //user prefs may have changed
    if([self _isAutomaticUpdateAndOk:forced])
       [self _updateServerStatus];
    else
        [self _destroyRequest];
}

- (void) serverStatusUpdateReceived:(NSNotification *)notification {
    logDebug(@"serverStatusUpdateReceived:");
    //user prefs may have changed
    if([self _isAutomaticUpdateAndOk:forced])
        [self _updateHostsInfo];
    else
        [self _destroyRequest];
}


- (void) hostsInfoUpdateReceived:(NSNotification *)notification {
    logDebug(@"hostsInfoUpdateReceived:");
    //user prefs may have changed
    if([self _isAutomaticUpdateAndOk:forced])
        [self _updateApplicationsInfo];
    else
        [self _destroyRequest];
}


- (void) applicationsInfoUpdateReceived:(NSNotification *)notification {
    logDebug(@"applicationsInfoUpdateReceived:");
    //user prefs may have changed
    if([self _isAutomaticUpdateAndOk:forced])
        [self _updateApplicationsStatus];
    else
        [self _destroyRequest];
}

- (void) applicationsStatusUpdateReceived:(NSNotification *)notification {
    logDebug(@"applicationsStatusUpdateReceived:");
     [dataSource postMessage:
         NSLocalizedString(
           @"TCSTomcatManagerProxy.statusMsg.updateComplete"
           ,nil)
         ];
    [componentView reloadData];

    /* DONE */
    [self _destroyRequest];
}

- (void) applicationStartResponseReceived:(NSNotification *)notification {
    logDebug(@"applicationStartResponseReceived:");
    [dataSource postMessage:
        [[notification userInfo] objectForKey:TCSManagerResponseMessage]];
    
    [componentView reloadData];
    
    /* DONE */
    [self _destroyRequest];
}

- (void) applicationStopResponseReceived:(NSNotification *)notification {
    logDebug(@"applicationStopResponseReceived:");
    [dataSource postMessage:
        [[notification userInfo] objectForKey:TCSManagerResponseMessage]];
    [componentView reloadData];
    
    /* DONE */
    [self _destroyRequest];
}

- (void) applicationReloadResponseReceived:(NSNotification *)notification {
    logDebug(@"applicationReloadResponseReceived:");
    [dataSource postMessage:
        [[notification userInfo] objectForKey:TCSManagerResponseMessage]];
    [componentView reloadData];
    
    /* DONE */
    [self _destroyRequest];
}

- (void) applicationDeployResponseReceived:(NSNotification *)notification {
    logDebug(@"applicationDeployResponseReceived:");
    [dataSource postMessage:
        [[notification userInfo] objectForKey:TCSManagerResponseMessage]];
    [componentView reloadData];
    
    /* DONE */
    [self _destroyRequest];
}

- (void) applicationUndeployResponseReceived:(NSNotification *)notification {
    logDebug(@"applicationUndeployResponseReceived:");
    [dataSource postMessage:
        [[notification userInfo] objectForKey:TCSManagerResponseMessage]];
    id component = [notification object];
    logDebug(@"component = %@",component);
    logDebug(@"component.parent = %@",[component parent]);
    [componentView reloadData];
    
    /* DONE */
    [self _destroyRequest];
}

- (void) componentUpdateFailed:(NSNotification *)notification {
    logDebug(@"componentUpdateFailed:");
    [dataSource postFormat:
        NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.requestFailed",nil)
        ,[notification object]];
    /* DONE */
    [self _destroyRequest];
}

- (void) userCanceledAuthentication:(NSNotification *)notification {
    logDebug(@"userCanceledAuthentication:");
    [self cancelCurrentRequest:self];
}


# pragma mark Observations

- (void) registerObservations {
//general updates
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(serverInfoUpdateReceived:) 
               name:TCSNotifcationServerInfoUpdateReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(serverStatusUpdateReceived:) 
               name:TCSNotifcationServerStatusUpdateReceived
             object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(connectorsInfoUpdateReceived:) 
               name:TCSNotifcationConnectorsInfoUpdateReceived
             object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(hostsInfoUpdateReceived:) 
               name:TCSNotifcationHostsInfoUpdateReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationsInfoUpdateReceived:) 
               name:TCSNotifcationApplicationsInfoUpdateReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationsStatusUpdateReceived:) 
               name:TCSNotifcationApplicationsStatusUpdateReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationStartResponseReceived:) 
               name:TCSNotifcationApplicationStartResponseReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationStopResponseReceived:) 
               name:TCSNotifcationApplicationStopResponseReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationReloadResponseReceived:) 
               name:TCSNotifcationApplicationReloadResponseReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationDeployResponseReceived:) 
               name:TCSNotifcationApplicationDeployResponseReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(applicationUndeployResponseReceived:) 
               name:TCSNotifcationApplicationUndeployResponseReceived
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(componentUpdateFailed:) 
               name:TCSNotifcationComponentUpdateFailed
             object:nil];    
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(userCanceledAuthentication:) 
               name:TCSNotifcationComponentUpdateAuthenticationCanceled
             object:nil];    
}

- (void) removeObservations {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation TCSTomcatManagerProxy (Private) 

- (BOOL) _isAutomaticUpdateAndOk:(BOOL)force {
    BOOL okToUpdate = YES;
    if([[TCSPrefController sharedPrefController] manualComponentUpdates] && !force) 
        okToUpdate = NO;
    logDebug(@"okToUpdate:%d",okToUpdate);
    return okToUpdate;
}

- (BOOL) _initRequestForKitty:(TCSKitty *)tk forced:(BOOL)force {
    BOOL okToUpdate = YES;
    if([self isUpdating] ) {
        [self cancelCurrentRequest:self];
        [dataSource postMessage:@""];
    }
    if(![tk isRunning]) {
        okToUpdate = NO;
    } else {
        [self _startProgressAnimation];
        updatingKitty = [tk retain];
        forced = force;
        host = [[@"http://localhost:" stringByAppendingString:
            [updatingKitty defaultHttpPort]] retain];
    }
    logDebug(@"okToUpdate:%d",okToUpdate);
    return okToUpdate;
}

- (void) _makeMangerRequest:(NSURLRequest *)request delegate:(id)delegate  {
    logDebug(@"Initiating request(%@)",request);
    [self setCurrentRequestConnection:
        [[NSURLConnection alloc] 
            initWithRequest:request 
                   delegate:delegate]];
    [self _validateConnectionForURL:[request URL]];
}

- (void) _startURLConnection:(NSString *)urlString delegate:(id)delegate {
    NSURL *url = [NSURL URLWithString:urlString]; 
    NSURLRequest *request=
        [NSURLRequest requestWithURL:url
                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                     timeoutInterval:MANAGER_REQUEST_TIMEOUT];        
    logDebug(@"Initiating request(%@)",request);
    [self setCurrentRequestConnection:
        [[NSURLConnection alloc] 
            initWithRequest:request 
                   delegate:delegate]];
    [self _validateConnectionForURL:url];
}

- (void) _validateConnectionForURL:(NSURL *)url {
    if (!currentRequestConnection) {
        logError(@"Manager connection (%@) could not be made",currentRequestConnection);
        [dataSource postFormat:
            NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.requestFailed",nil)
            ,url];
    } else {
        logDebug(@"Started connection (%@)",currentRequestConnection);
        [dataSource postFormat:
            NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.requesting",nil)
            ,url];
        /*
        NSString *msg = [NSString stringWithFormat: 
            NSLocalizedString(@"TCSTomcatManagerProxy.statusMsg.requesting",nil)
            ,url];
        logDebug(@"msg = %@",msg);
        [dataSource postMessage:msg];
         */
    }    
}

- (void) _destroyRequest {
    [updatingKitty release];
    updatingKitty = nil;
    [self _stopProgressAnimation];
}

- (void) _startProgressAnimation {
    [dataSource startProgressAnimation];
}

- (void) _stopProgressAnimation {
    [dataSource stopProgressAnimation];
}

- (void) _updateServerInfo {
    NSString *serverInfoURLString = [host stringByAppendingString:serverInfoPath];
    [self _startURLConnection:serverInfoURLString 
                     delegate:[TCSServerInfoResponseDelegate withComponent:updatingKitty]];
}

- (void) _updateConnectorsInfo {
    NSString *connectorsURLString = [host stringByAppendingString:connectorsInfoPath];
    [self _startURLConnection:connectorsURLString 
                     delegate:[TCSConnectorsInfoResponseDelegate withComponent:updatingKitty]];
}

- (void) _updateServerStatus {
    NSString *serverStatusURLString = [host stringByAppendingString:serverStatusPath];
    [self _startURLConnection:serverStatusURLString 
                     delegate:[TCSServerStatusResponseDelegate withComponent:updatingKitty]];
}

- (void) _updateHostsInfo {
    NSString *hostsURLString = [host stringByAppendingString:hostsInfoPath];
    [self _startURLConnection:hostsURLString 
                     delegate:[TCSHostsInfoResponseDelegate  withComponent:updatingKitty]];
}

- (void) _updateApplicationsInfo {
    NSString *applicationsInfoURLString = [host stringByAppendingString:applicationsInfoPath];
    [self _startURLConnection:applicationsInfoURLString 
                     delegate:[TCSApplicationsInfoResponseDelegate  withComponent:updatingKitty]];
}

- (void) _updateApplicationsStatus {
    NSString *applicationsStatusURLString = [host stringByAppendingString:applicationsStatusPath];
    [self _startURLConnection:applicationsStatusURLString 
                     delegate:[TCSApplicationsStatusResponseDelegate  withComponent:updatingKitty]];
}



@end




