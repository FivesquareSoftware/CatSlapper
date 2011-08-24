//
//  TCSConstants.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/28/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//constant integers
#define MANAGER_REQUEST_TIMEOUT 60
#define LOG_FILE_TAIL_BUFFER 1024
#define LOG_FILE_TAIL_INTERVAL 1

#define DOCK_MENU_KITTY_ITEM_TAG 999
#define DOCK_MENU_TOGGLE_ITEM_TAG 1
#define DOCK_MENU_RESTART_ITEM_TAG 2

//one line is roughly 100 bytes
extern unsigned long long LOG_FILE_TAIL_OFFSET;
extern unsigned long long LOG_FILE_MAX_STORAGE;

//output types
enum TCSOutputType {
    TCS_STDOUT
    , TCS_STDERR
    , TCS_SERVER_LOG
    , TCS_HOST_LOG
};

//startup types
typedef enum _TCSAutomaticStartupType {
    TCS_NEVER
    , TCS_SYSTEM_BOOT
    , TCS_USER_LOGIN
} TCSAutomaticStartupType;



//tomcat settings
extern NSString *TCSTomcatDefaultShutdownPort;
extern NSString *TCSTomcatDefaultHttpPort;
extern NSString *TCSTomcatDefaultAjpPort;

//file paths
extern NSString *TCSJavaHome;
extern NSString *TCSJavaJRE;
extern NSString *TCSServerConfigFile;
extern NSString *TCSServerLogFile;
extern NSString *TCSServerStartupScript;
extern NSString *TCSServerShutdownScript;
extern NSString *TCSServerPidFile;
extern NSString *TCSTomcatBootstrapJar;
extern NSString *TCSAcknowledgementsFile;
extern NSString *TCSLicenseFile;
extern NSString *TCSTomcatRunningTomcatFile;

//URLS
extern NSString *TCSURLTomcatOnlineDocs;
extern NSString *TCSURLFivesquareWebsite;
extern NSString *TCSURLFivesquareOnlineStore;
extern NSString *TCSURLFivesquareCatslapperFeedback;
extern NSString *TCSURLFivesquareCatSlapperNewestVersion;

// help keys
extern NSString *TCSCatSlapperHelpBook;
extern NSString *TCSCatSlapperHelpManagerAnchor;
extern NSString *TCSCatSlapperHelpLaunchDaemonsAnchor;
extern NSString *TCSCatSlapperHelpACLAnchor;
extern NSString *TCSCatSlapperHelpRunningPrivilegedAnchor;
extern NSString *TCSCatSlapperHelpRepairPermissionsAnchor;
extern NSString *TCSCatSlapperHelpInstallerAnchor;
extern NSString *TCSCatSlapperHelpDeployAnchor;

// daemon keys
extern NSString *TCSDaemonKeyDisabled;
extern NSString *TCSDaemonKeyEnvironmentVariables;
extern NSString *TCSDaemonKeyLabel;
extern NSString *TCSDaemonKeyProgram;
extern NSString *TCSDaemonKeyServiceDescription;
extern NSString *TCSDaemonKeyStandardErrorPath;
extern NSString *TCSDaemonKeyStandardOutPath;
extern NSString *TCSDaemonKeyUserName;

//environment
extern NSString *TCSEnvKeyCatalinaHome;
extern NSString *TCSEnvKeyCatalinaBase;
extern NSString *TCSEnvKeyCatalinaOpts;
extern NSString *TCSEnvKeyCatalinaPid;
extern NSString *TCSEnvKeyJpdaTransport;
extern NSString *TCSEnvKeyJpdaAddress;
extern NSString *TCSEnvKeyJavaHome;

//strings for keys
extern NSString *TCSWindowSaveName;
extern NSString *TCSToolbarIdentifier;
extern NSString *TCSPrefWindowSaveName;
extern NSString *TCSAuthWindowSaveName;
extern NSString *TCSConsoleServerArgFilename;
extern NSString *TCSConsoleServerArgRcvPort;
extern NSString *TCSConsoleServerArgSendPort;
extern NSString *TCSErrorWindowSaveName;
extern NSString *TCSComponentUpdateArgKitty;
extern NSString *TCSComponentUpdateArgForced;
extern NSString *TCSManagerResponseMessage;

//attributes
extern NSString *TCSTemporaryAttributeName;
extern NSString *TCSTemporaryAttributeStdOut;
extern NSString *TCSTemporaryAttributeStdErr;
extern NSString *TCSTemporaryAttributeServerLog;
extern NSString *TCSTemporaryAttributeHostLog;

//user info keys
extern NSString *TCSUserInfoKeyManagerResponseDelegate;
extern NSString *TCSUserInfoKeyContextPath;

//defaults
extern NSString *TCSUserDefaultsKittens;
extern NSString *TCSUserDefaultsSelectedKitty;
extern NSString *TCSUserDefaultsSelectedPrefPane;
extern NSString *TCSUserDefaultsUseShellEnv;
extern NSString *TCSUserDefaultsDefaultValues;
extern NSString *TCSUserDefaultsTextColorBackground;
extern NSString *TCSUserDefaultsTextColorStdout;
extern NSString *TCSUserDefaultsTextColorStderr;
extern NSString *TCSUserDefaultsTextColorServerLog;
extern NSString *TCSUserDefaultsTextColorHostLog;
extern NSString *TCSUserDefaultsConsoleFont;
extern NSString *TCSUserDefaultsMaxInfoOpenSize;
extern NSString *TCSUserDefaultsMaxConsoleOpenSize;
extern NSString *TCSUserDefaultsManualComponentUpdates;
extern NSString *TCSUserDefaultsComponentUpdatesEvery;
extern NSString *TCSUserDefaultsShouldMeow;
extern NSString *TCSUserDefaultsLastBetaCheck;
extern NSString *TCSUserDefaultsRegistrationCode;
extern NSString *TCSUserDefaultsRegistrationName;
extern NSString *TCSUserDefaultsFirstRun;
extern NSString *TCSUserDefaultsFirstRunVersion;
extern NSString *TCSUserDefaultsTriggerUpdates;
extern NSString *TCSUserDefaultsShouldAskAboutSettingACLs;
extern NSString *TCSUserDefaultsCanSetACLs;
extern NSString *TCSUserDefaultsDidSetACLs;
extern NSString *TCSUserDefaultsShouldAskAboutRunningPrivileged;
extern NSString *TCSUserDefaultsCanRunTomcatsPrivileged;
extern NSString *TCSUserDefaultsShouldAskAboutRepairingPermissions;
extern NSString *TCSUserDefaultsCanRepairPermissions;
extern NSString *TCSUserDefaultsNewVersionCheck;

//exceptions
extern NSString *TCSExceptionInvalidKitty;
extern NSString *TCSExceptionCatalinaHomeNotSet;
extern NSString *TCSExceptionCatalinaHomeNotDirectory;
extern NSString *TCSExceptionCatalinaHomeNotValidHome;
extern NSString *TCSExceptionCatalinaBaseNotDirectory;
extern NSString *TCSExceptionJavaHomeNotDirectory;
extern NSString *TCSExceptionDuplicateCats;
extern NSString *TCSExceptionPrivateMethod;
extern NSString *TCSExceptionBadConsoleShutdown;
extern NSString *TCSExceptionCannotCreateCrashFile;
extern NSString *TCSExceptionSubclassMustImplement;
extern NSString *TCSExceptionAuthorizationFailed;
extern NSString *TCSExceptionCouldNotEnableACLs;
extern NSString *TCSExceptionErrorReadingDaemonFile;
extern NSString *TCSExceptionErrorWritingToDaemonFile;
extern NSString *TCSExceptionInvalidDaemonFile;
extern NSString *TCSExceptionCouldNotAddACLEntry;
extern NSString *TCSExceptionCouldNotRepairPermissions;

//notifications
extern NSString *TCSNotifcationSignalCaught;
extern NSString *TCSNotifcationServerInfoUpdateReceived;
extern NSString *TCSNotifcationServerStatusUpdateReceived;
extern NSString *TCSNotifcationConnectorsInfoUpdateReceived;
extern NSString *TCSNotifcationHostsInfoUpdateReceived;
extern NSString *TCSNotifcationApplicationsInfoUpdateReceived;
extern NSString *TCSNotifcationApplicationsStatusUpdateReceived;
extern NSString *TCSNotifcationApplicationStartResponseReceived;
extern NSString *TCSNotifcationApplicationStopResponseReceived;
extern NSString *TCSNotifcationApplicationReloadResponseReceived;
extern NSString *TCSNotifcationApplicationDeployResponseReceived;
extern NSString *TCSNotifcationApplicationUndeployResponseReceived;
extern NSString *TCSNotifcationComponentUpdateFailed;
extern NSString *TCSNotifcationComponentUpdateAuthenticationCanceled;
extern NSString *TCSNotifcationTomcatInstalled;
extern NSString *TCSNotifcationRegistrationChanged;
