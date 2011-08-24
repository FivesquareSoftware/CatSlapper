//
//  TCSTomcatManagerProxy+Private.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/29/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSTomcatManagerProxy (Private) 
- (BOOL) _isAutomaticUpdateAndOk:(BOOL) forced; 
- (BOOL) _initRequestForKitty:(TCSKitty *)tk forced:(BOOL)force;
- (void) _makeMangerRequest:(NSURLRequest *)request delegate:(id)delegate;
- (void) _startURLConnection:(NSString *)urlString delegate:(id)delegate;
- (void) _validateConnectionForURL:(NSURL *)url;
- (void) _destroyRequest;

- (void) _startProgressAnimation;
- (void) _stopProgressAnimation;

- (void) _updateServerInfo;
- (void) _updateServerStatus;
- (void) _updateConnectorsInfo;
- (void) _updateHostsInfo;
- (void) _updateApplicationsInfo;
- (void) _updateApplicationsStatus;
@end
