//
//  TCSTomcatManagerAuthController.m
//  TomcatSlapper
//
//  Created by John Clayton on 2/1/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSTomcatManagerAuthController.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSPrefController.h"
#import "TCSComponent.h"


@implementation TCSTomcatManagerAuthController

static TCSTomcatManagerAuthController *controller;


// OBJECT STUFF ============================================================= //

- (id) init {
    [NSException raise:TCSExceptionPrivateMethod 
                format:@"Private method"];
}

- (id) _init {
    if(self = [super init]) {
        shouldSaveCredentials = NO;
    }
    return self;
}


// SINGLETON AUTH CONTROLLER ================================================ //

+ (id) sharedAuthController {
    if(controller == nil) {
        controller = [[TCSTomcatManagerAuthController alloc] _init];
        [NSBundle loadNibNamed:@"Authorize" owner:controller];
    }
    return controller;
}

// AUTHORIZATION ============================================================= //


- (NSURLCredential *) authorizeForChallenge:(NSURLAuthenticationChallenge *)challenge
                                  component:(TCSComponent *)component {    
    NSURLProtectionSpace *pSpace = [challenge protectionSpace];
    NSString *name = [[component rootComponent] name];
    NSString *protocol = [pSpace protocol];
    NSString *host = [pSpace host];
    int port = [pSpace port];
    NSString *realm = [pSpace realm];
    [self setUserMessage:[NSString stringWithFormat:
         NSLocalizedString(@"TCSTomcatManagerAuthController.userMessage",nil)
        , name        
        , realm
        , host
        , port]];
    
    NSURLCredential *creds = nil;
    
    // we can get an unattached sheet if this happens in background
    // and we use NSApp to get window so it has to be set
    if(mainWindow == nil) return nil;
    
    [NSApp beginSheet: authPanel
       modalForWindow: mainWindow
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil]; 
    [NSApp runModalForWindow:mainWindow]; //no other activity
    // Sheet is up here
    logDebug(@"auth process done");
    logDebug(@"userName,password = (%@,%@)",userName,password);
   
    if(userName != nil && password != nil) {
        NSURLCredentialPersistence persistence = 
            [self shouldSaveCredentials] 
            ? NSURLCredentialPersistencePermanent
            : NSURLCredentialPersistenceForSession;
        creds = [NSURLCredential 
                    credentialWithUser:userName
                              password:password
                           persistence:persistence];
    }
    logDebug(@"returning credentials: %@",creds);
    return creds;
}

- (IBAction) cancelAuthorize:(id)sender {
    //sheet coming down
    [NSApp endSheet: authPanel];      
    [authPanel orderOut:self];
    
    [[NSNotificationCenter defaultCenter] 
            postNotificationName:TCSNotifcationComponentUpdateAuthenticationCanceled 
                          object:nil];
    
    if(![[TCSPrefController sharedPrefController] manualComponentUpdates]) {
        //a new alert asking if the user wants to turn off manager updates
        logDebug(@"asking user about disabling");
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\E"];
        [alert setMessageText:NSLocalizedString(@"TCSTomcatManagerAuthController.disableMessage",nil)];
        [alert setInformativeText:NSLocalizedString(@"TCSTomcatManagerAuthController.helpMessage",nil)];
        [alert setShowsHelp:YES];
        [alert setHelpAnchor:TCSCatSlapperHelpManagerAnchor];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[NSApp mainWindow] 
                          modalDelegate:self 
                         didEndSelector:@selector(disableManagerAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:nil];
        //sheet up
        logDebug(@"alert sheet is done");
    } else {
        [NSApp stopModal];
    }
}

- (void)disableManagerAlertDidEnd:(NSAlert *)alert 
                       returnCode:(int)returnCode 
                      contextInfo:(void *)contextInfo {
    [NSApp stopModal];

    //sheet down
    logDebug(@"returnCode:%d",returnCode);
    if (returnCode == NSAlertFirstButtonReturn) {
        logDebug(@"disabling further authorizations");
        [[TCSPrefController sharedPrefController] setManualComponentUpdates:YES];
    }    
}

- (IBAction) processAuthorize:(id)sender {
    [NSApp stopModal];
    //sheet coming down
    [NSApp endSheet: authPanel];      
    [authPanel orderOut:self];
}


// KVC ====================================================================== //

- (void) setMainWindow:(NSWindow *) window {
    mainWindow = window; //retained elsewhere
}

- (NSString *)userMessage {
    return userMessage;
}

- (void)setUserMessage:(NSString *)newUserMessage {
    [newUserMessage retain];
    [userMessage release];
    userMessage = newUserMessage;
}

- (BOOL)shouldSaveCredentials {
    return shouldSaveCredentials;
}

- (void)setShouldSaveCredentials:(BOOL)newShouldSaveCredentials {
    shouldSaveCredentials = newShouldSaveCredentials;
}

- (NSString *)userName {
    return userName;
}

- (void)setUserName:(NSString *)newUserName {
    [newUserName retain];
    [userName release];
    userName = newUserName;
}

- (NSString *)password {
    return password;
}

- (void)setPassword:(NSString *)newPassword {
    logDebug(@"setPassword:%@",newPassword);
    [newPassword retain];
    [password release];
    password = newPassword;
}


@end
