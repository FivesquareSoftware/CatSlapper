//
//  TCSInstallerController.h
//  TomcatSlapper
//
//  Created by John Clayton on 4/30/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCSKitty;

@interface TCSInstallerController : NSWindowController {
    TCSKitty *kitty;  
    NSString *installerPath;
    BOOL isInstalling;
    BOOL readInBackground;
    NSString *stdErrFilePath;
    NSFileHandle *taskStdErrHandle;

    NSString *managerUser;
    NSString *managerPasswd;
    
    int ticks,count;
    
    IBOutlet NSObjectController *installingKittyController;

    IBOutlet NSWindow *entryWin;
    IBOutlet NSTextField *entryField;
    IBOutlet NSTextField *catalinaOptsField;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextView *messages;
    IBOutlet NSButton *installButton;
}

+ (TCSInstallerController *) sharedInstallerController;

- (IBAction) install:(id)sender;
- (IBAction) displayInstallerHelp:(id)sender;
- (IBAction) browse:(id)sender;
- (IBAction) editOpts:(id)sender;
- (IBAction) didEndEditOpts:(id)sender;

- (BOOL) validConfiguration; 

- (TCSKitty *)kitty;
- (void)setKitty:(TCSKitty *)newKitty;
- (NSString *)stdErrFilePath;
- (void)setStdErrFilePath:(NSString *)newStdErrFilePath;
- (NSFileHandle *)taskStdErrHandle;
- (void)setTaskStdErrHandle:(NSFileHandle *)newTaskStdErrHandle;
- (NSString *)managerUser;
- (void)setManagerUser:(NSString *)newManagerUser;
- (NSString *)managerPasswd;
- (void)setManagerPasswd:(NSString *)newManagerPasswd;


- (void) registerObservations;
- (void) removeObservations;

- (NSAttributedString *) errorString:(NSString *)errorString;

@end
