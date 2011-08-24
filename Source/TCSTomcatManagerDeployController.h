//
//  TCSTomcatManagerDeployController.h
//  TomcatSlapper
//
//  Created by John Clayton on 6/15/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSHostComponent;

@interface TCSTomcatManagerDeployController : NSObject {
    NSURLRequest *request;
    TCSHostComponent *host;
    NSMutableString *urlString;
    
    IBOutlet NSWindow *deployPanel;
    
    NSString *deployContextPath;
    NSString *deployConfigFileURL;
    NSString *deployWarURL;
    NSURL *deployWarLocalFileURL;

}

+ (TCSTomcatManagerDeployController *) sharedDeployController;

- (NSURLRequest *) deploymentRequestToHost:(TCSHostComponent *)host;

- (IBAction) createRemoteDeploymentRequest:(id)sender;
- (IBAction) createLocalDeploymentRequest:(id)sender;
- (IBAction) cancelDeployment:(id)sender;
- (IBAction) browse:(id)sender;
- (IBAction) displayDeployHelp:(id)sender;

- (NSURLRequest *)request;
- (void)setRequest:(NSURLRequest *)newRequest;
- (TCSHostComponent *)host;
- (void)setHost:(TCSHostComponent *)newHost;
- (NSMutableString *)urlString;
- (void)setUrlString:(NSMutableString *)newUrlString;

- (NSString *)deployContextPath;
- (void)setDeployContextPath:(NSString *)newDeployContextPath;
- (NSString *)deployConfigFileURL;
- (void)setDeployConfigFileURL:(NSString *)newDeployConfigFileURL;
- (NSString *)deployWarURL;
- (void)setDeployWarURL:(NSString *)newDeployWarURL;
- (NSURL *)deployWarLocalFileURL;
- (void)setDeployWarLocalFileURL:(NSURL *)newDeployWarLocalFileURL;
- (NSString *)deployWarFileName;


- (void) _stopSheet;

@end
