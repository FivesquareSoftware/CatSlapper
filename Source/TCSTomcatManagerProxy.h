//
//  TCSTomcatManagerProxy.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/4/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCSKitty;
@class TCSServerInfoResponseDelegate;
@class TCSConnectorsInfoResponseDelegate;
@class TCSHostsInfoResponseDelegate;
@class TCSComponentViewDataSource;
@class TCSHostComponent;
@class TCSAppComponent;

@interface TCSTomcatManagerProxy : NSObject {
    TCSKitty *updatingKitty;
    BOOL forced;
    NSString *host;
    NSURLConnection *currentRequestConnection;
    
    IBOutlet NSOutlineView *componentView;
    IBOutlet TCSComponentViewDataSource *dataSource;
}

- (BOOL) isUpdating;
- (BOOL) isUpdatingKitty:(TCSKitty *)tk;
- (IBAction) cancelCurrentRequest:(id)sender;

- (void) updateComponentsForKitty:(TCSKitty *)tk;
- (void) updateComponentsForKitty:(TCSKitty *)tk force:(BOOL)force;
- (void) startApplication:(TCSAppComponent *)app forKitty:(TCSKitty *)tk;
- (void) stopApplication:(TCSAppComponent *)app forKitty:(TCSKitty *)tk;
- (void) reloadApplication:(TCSAppComponent *)app forKitty:(TCSKitty *)tk;
- (void) deploymentRequest:(NSURLRequest *) request 
                    onHost:(TCSHostComponent *)host
                  forKitty:(TCSKitty *)tk ;
- (void) undeployApplication:(TCSAppComponent *)app;
- (void) registerObservations;
- (void) removeObservations;

@end
