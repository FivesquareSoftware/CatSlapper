//
//  TCSConstants.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/28/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSConstants.h"

// tails
unsigned long long LOG_FILE_TAIL_OFFSET = (100*10);
unsigned long long LOG_FILE_MAX_STORAGE = (100*1000);


//tomcat settings
NSString *TCSTomcatDefaultShutdownPort = @"8005";
NSString *TCSTomcatDefaultHttpPort = @"8080";
NSString *TCSTomcatDefaultAjpPort = @"8009";

//file paths
NSString *TCSJavaHome = @"/Library/Java/Home";
NSString *TCSJavaJRE = @"/bin/java";
NSString *TCSServerConfigFile = @"conf/server.xml";
NSString *TCSServerLogFile = @"logs/catalina.out";
NSString *TCSServerStartupScript = @"/bin/startup.sh";
NSString *TCSServerShutdownScript = @"/bin/shutdown.sh";
NSString *TCSServerPidFile = @"/temp/pid.txt";
NSString *TCSTomcatBootstrapJar = @"/bin/bootstrap.jar";
NSString *TCSAcknowledgementsFile = @"Acknowledgements";
NSString *TCSLicenseFile = @"License";
NSString *TCSTomcatRunningTomcatFile = @"RUNNING";


//URLS
NSString *TCSURLTomcatOnlineDocs = @"http://jakarta.apache.org/tomcat";
NSString *TCSURLFivesquareWebsite = @"http://www.fivesquaresoftware.com/catslapper/";
NSString *TCSURLFivesquareOnlineStore = @"http://store.eSellerate.net/s.aspx?s=STR7382540095";
NSString *TCSURLFivesquareCatslapperFeedback = @"mailto:talkback@fivesquaresoftware.com";
NSString *TCSURLFivesquareCatSlapperNewestVersion = @"http://www.fivesquaresoftware.com/versions/catslapper.plist";

// help keys
NSString *TCSCatSlapperHelpBook = @"Cat Slapper Help";
NSString *TCSCatSlapperHelpManagerAnchor = @"CatSlapper_TomcatManager";
NSString *TCSCatSlapperHelpLaunchDaemonsAnchor = @"CatSlapper_LaunchDaemons";
NSString *TCSCatSlapperHelpACLAnchor = @"CatSlapper_ACLs";
NSString *TCSCatSlapperHelpRunningPrivilegedAnchor = @"CatSlapper_RunningPrivileged";
NSString *TCSCatSlapperHelpRepairPermissionsAnchor = @"CatSlapper_RepairingPermissions";
NSString *TCSCatSlapperHelpInstallerAnchor = @"CatSlapper_Installer";
NSString *TCSCatSlapperHelpDeployAnchor = @"CatSlapper_Deploy";

// daemon keys
NSString *TCSDaemonKeyDisabled = @"Disabled";
NSString *TCSDaemonKeyEnvironmentVariables = @"EnvironmentVariables";
NSString *TCSDaemonKeyLabel = @"Label";
NSString *TCSDaemonKeyProgram = @"Program";
NSString *TCSDaemonKeyServiceDescription = @"ServiceDescription";
NSString *TCSDaemonKeyStandardErrorPath = @"StandardErrorPath";
NSString *TCSDaemonKeyStandardOutPath = @"StandardOutPath";
NSString *TCSDaemonKeyUserName = @"UserName";

//environment
NSString *TCSEnvKeyCatalinaHome = @"CATALINA_HOME";
NSString *TCSEnvKeyCatalinaBase = @"CATALINA_BASE";
NSString *TCSEnvKeyJavaHome = @"JAVA_HOME";
NSString *TCSEnvKeyCatalinaOpts = @"CATALINA_OPTS";
NSString *TCSEnvKeyCatalinaPid = @"CATALINA_PID";
NSString *TCSEnvKeyJpdaTransport = @"JPDA_TRANSPORT";
NSString *TCSEnvKeyJpdaAddress = @"JPDA_ADDRESS";

//strings for keys
NSString *TCSWindowSaveName = @"TCSWindowSaveName";
NSString *TCSToolbarIdentifier = @"TCSToolbarIdentifier";
NSString *TCSPrefWindowSaveName = @"TCSPrefWindowSaveName";
NSString *TCSAuthWindowSaveName = @"TCSAuthWindowSaveName";
NSString *TCSConsoleServerArgFilename = @"TCSConsoleServerArgFilename";
NSString *TCSConsoleServerArgRcvPort = @"TCSConsoleServerArgRcvPort";
NSString *TCSConsoleServerArgSendPort = @"TCSConsoleServerArgSendPort";
NSString *TCSErrorWindowSaveName = @"TCSErrorWindowSaveName"; 
NSString *TCSComponentUpdateArgKitty = @"TCSComponentUpdateArgKitty";
NSString *TCSComponentUpdateArgForced = @"TCSComponentUpdateArgForced";
NSString *TCSManagerResponseMessage = @"TCSManagerResponseMessage";


//attributes
NSString *TCSTemporaryAttributeName = @"TCSTemporaryAttributeName";
NSString *TCSTemporaryAttributeStdOut = @"TCSTemporaryAttributeStdOut";
NSString *TCSTemporaryAttributeStdErr = @"TCSTemporaryAttributeStdErr";
NSString *TCSTemporaryAttributeServerLog = @"TCSTemporaryAttributeServerLog";
NSString *TCSTemporaryAttributeHostLog = @"TCSTemporaryAttributeHostLog";

// user info keys
NSString *TCSUserInfoKeyManagerResponseDelegate = @"TCSUserInfoKeyManagerResponseDelegate";
NSString *TCSUserInfoKeyContextPath = @"TCSUserInfoKeyContextPath";

//defaults
NSString *TCSUserDefaultsKittens = @"TCSUserDefaultsKittens";
NSString *TCSUserDefaultsSelectedKitty = @"TCSUserDefaultsSelectedKitty";
NSString *TCSUserDefaultsSelectedPrefPane = @"TCSUserDefaultsSelectedPrefPane";
NSString *TCSUserDefaultsUseShellEnv = @"TCSUserDefaultsUseShellEnv";
NSString *TCSUserDefaultsDefaultValues = @"TCSUserDefaultsDefaultValues";
NSString *TCSUserDefaultsTextColorBackground = @"TCSUserDefaultsTextColorBackground";
NSString *TCSUserDefaultsTextColorStdout = @"TCSUserDefaultsTextColorStdout";
NSString *TCSUserDefaultsTextColorStderr = @"TCSUserDefaultsTextColorStderr";
NSString *TCSUserDefaultsTextColorServerLog = @"TCSUserDefaultsTextColorServerLog";
NSString *TCSUserDefaultsTextColorHostLog = @"TCSUserDefaultsTextColorHostLog";
NSString *TCSUserDefaultsConsoleFont = @"TCSUserDefaultsConsoleFont";
NSString *TCSUserDefaultsMaxInfoOpenSize = @"TCSUserDefaultsMaxInfoOpenSize";
NSString *TCSUserDefaultsMaxConsoleOpenSize = @"TCSUserDefaultsMaxConsoleOpenSize";
NSString *TCSUserDefaultsManualComponentUpdates = @"TCSUserDefaultsManualComponentUpdates";
NSString *TCSUserDefaultsShouldMeow = @"TCSUserDefaultsShouldMeow";
NSString *TCSUserDefaultsComponentUpdatesEvery = @"TCSUserDefaultsComponentUpdatesEvery";
NSString *TCSUserDefaultsLastBetaCheck = @"TCSUserDefaultsLastBetaCheck";
NSString *TCSUserDefaultsRegistrationCode = @"TCSUserDefaultsRegistrationCode";
NSString *TCSUserDefaultsRegistrationName = @"TCSUserDefaultsRegistrationName";
NSString *TCSUserDefaultsFirstRun = @"TCSUserDefaultsFirstRun";
NSString *TCSUserDefaultsFirstRunVersion = @"TCSUserDefaultsFirstRunVersion";
NSString *TCSUserDefaultsTriggerUpdates = @"TCSUserDefaultsTriggerUpdates";
NSString *TCSUserDefaultsShouldAskAboutSettingACLs = @"TCSUserDefaultsShouldAskAboutSettingACLs";
NSString *TCSUserDefaultsCanSetACLs = @"TCSUserDefaultsCanSetACLs";
NSString *TCSUserDefaultsDidSetACLs = @"TCSUserDefaultsDidSetACLs";
NSString *TCSUserDefaultsShouldAskAboutRunningPrivileged = @"TCSUserDefaultsShouldAskAboutRunningPrivileged";
NSString *TCSUserDefaultsCanRunTomcatsPrivileged = @"TCSUserDefaultsCanRunTomcatsPrivileged";
NSString *TCSUserDefaultsShouldAskAboutRepairingPermissions = @"TCSUserDefaultsShouldAskAboutRepairingPermissions";
NSString *TCSUserDefaultsCanRepairPermissions = @"TCSUserDefaultsCanRepairPermissions";
NSString *TCSUserDefaultsNewVersionCheck = @"TCSUserDefaultsNewVersionCheck";



//exceptions
NSString *TCSExceptionInvalidKitty = @"TCSExceptionInvalidKitty";
NSString *TCSExceptionCatalinaHomeNotSet = @"TCSExceptionCatalinaHomeNotSet";
NSString *TCSExceptionCatalinaHomeNotDirectory = @"TCSExceptionCatalinaHomeNotDirectory";
NSString *TCSExceptionCatalinaHomeNotValidHome = @"TCSExceptionCatalinaHomeNotValidHome";
NSString *TCSExceptionCatalinaBaseNotDirectory = @"TCSExceptionCatalinaBaseNotDirectory";
NSString *TCSExceptionJavaHomeNotDirectory = @"TCSExceptionJavaHomeNotDirectory";
NSString *TCSExceptionDuplicateCats = @"TCSExceptionDuplicateCats";
NSString *TCSExceptionPrivateMethod = @"TCSExceptionPrivateMethod";
NSString *TCSExceptionBadConsoleShutdown = @"TCSExceptionBadConsoleShutdown";
NSString *TCSExceptionCannotCreateCrashFile = @"TCSExceptionCannotCreateCrashFile";
NSString *TCSExceptionSubclassMustImplement = @"TCSExceptionSubclassMustImplement";
NSString *TCSExceptionAuthorizationFailed = @"TCSExceptionAuthorizationFailed";
NSString *TCSExceptionCouldNotEnableACLs = @"TCSExceptionCouldNotEnableACLs";
NSString *TCSExceptionErrorReadingDaemonFile = @"TCSExceptionErrorReadingDaemonFile";
NSString *TCSExceptionErrorWritingToDaemonFile= @"TCSExceptionErrorWritingToDaemonFile";
NSString *TCSExceptionInvalidDaemonFile = @"TCSExceptionInvalidDaemonFile";
NSString *TCSExceptionCouldNotAddACLEntry = @"TCSExceptionCouldNotAddACLEntry";
NSString *TCSExceptionCouldNotRepairPermissions = @"TCSExceptionCouldNotRepairPermissions";


//notifications
NSString *TCSNotifcationSignalCaught = @"TCSNotifcationSignalCaught";
NSString *TCSNotifcationServerInfoUpdateReceived = @"TCSNotifcationServerInfoUpdateReceived";
NSString *TCSNotifcationServerStatusUpdateReceived = @"TCSNotifcationServerStatusUpdateReceived";
NSString *TCSNotifcationConnectorsInfoUpdateReceived = @"TCSNotifcationConnectorsInfoUpdateReceived";
NSString *TCSNotifcationHostsInfoUpdateReceived = @"TCSNotifcationHostsInfoUpdateReceived";
NSString *TCSNotifcationApplicationsInfoUpdateReceived = @"TCSNotifcationApplicationsUpdateReceived";
NSString *TCSNotifcationApplicationsStatusUpdateReceived = @"TCSNotifcationApplicationsStatusUpdateReceived";
NSString *TCSNotifcationApplicationStartResponseReceived = @"TCSNotifcationApplicationStartResponseReceived";
NSString *TCSNotifcationApplicationStopResponseReceived = @"TCSNotifcationApplicationStopResponseReceived";
NSString *TCSNotifcationApplicationReloadResponseReceived = @"TCSNotifcationApplicationReloadResponseReceived";
NSString *TCSNotifcationApplicationDeployResponseReceived = @"TCSNotifcationApplicationDeployResponseReceived";
NSString *TCSNotifcationApplicationUndeployResponseReceived = @"TCSNotifcationApplicationUndeployResponseReceived";
NSString *TCSNotifcationComponentUpdateFailed = @"TCSNotifcationComponentUpdateFailed";
NSString *TCSNotifcationComponentUpdateAuthenticationCanceled = @"TCSNotifcationComponentUpdateAuthenticationCanceled";
NSString *TCSNotifcationTomcatInstalled = @"TCSNotifcationTomcatInstalled";
NSString *TCSNotifcationRegistrationChanged = @"TCSNotifcationRegistrationChanged";
