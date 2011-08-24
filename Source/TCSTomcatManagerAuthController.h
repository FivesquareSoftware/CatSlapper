//
//  TCSTomcatManagerAuthController.h
//  TomcatSlapper
//
//  Created by John Clayton on 2/1/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSComponent;

@interface TCSTomcatManagerAuthController : NSObject {
    NSWindow *mainWindow;
    IBOutlet NSPanel *authPanel;
    NSString *userMessage;   
    
    BOOL shouldSaveCredentials;
    NSString *userName;
    NSString *password;
}

- (id) _init;
+ (id) sharedAuthController;
- (NSURLCredential *) authorizeForChallenge:(NSURLAuthenticationChallenge *)challenge
                                  component:(TCSComponent *)component;

- (IBAction) cancelAuthorize:(id)sender;
- (IBAction) processAuthorize:(id)sender;

- (void) setMainWindow:(NSWindow *) window;
- (NSString *)userMessage;
- (void)setUserMessage:(NSString *)newUserMessage;
- (BOOL)shouldSaveCredentials;
- (void)setShouldSaveCredentials:(BOOL)newShouldSaveCredentials;
- (NSString *)userName;
- (void)setUserName:(NSString *)newUserName;
- (NSString *)password;
- (void)setPassword:(NSString *)newPassword;

@end
