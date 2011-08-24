//
//  TCSUserShell.m
//  TomcatSlapper
//
//  Created by John Clayton on 10/14/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSUserShell.h"
#import "TCSIOUtils.h"
#import "TCSConstants.h"
#import "TCSLogger.h"


@implementation TCSUserShell

// STATIC VARS ============================================================== //

static NSString *tcsh = @"/bin/tcsh";
static NSString *bash = @"/bin/bash";


// USER SHELL =============================================================== //

+ (NSMutableDictionary *) currentEnvironmentFromUserShell {
    NSMutableDictionary *shellEnv = nil;
    NSDictionary *defaultEnv = [[NSProcessInfo processInfo] environment];
    NSString *userShell = [defaultEnv objectForKey:@"SHELL"];
    logTrace(@"userShell = %@",userShell);
    NSMutableDictionary *taskEnv = 
        [NSMutableDictionary dictionaryWithDictionary:defaultEnv];

    NSTask *shell = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *inPipe = [NSPipe pipe]; 
    if(outPipe == nil || inPipe == nil) {
        logError(@"Error creating pipe to get user taskEnv (%s)",strerror(errno));
        return nil;
    }
    NSFileHandle *readHandle = [outPipe fileHandleForReading];
    NSFileHandle *writeHandle = [inPipe fileHandleForWriting];
    NSMutableData *inData = [NSMutableData data];
    
    [shell setCurrentDirectoryPath:NSHomeDirectory()];
    [shell setLaunchPath:userShell];
    logTrace(@"shell.setEnvironment: %@",taskEnv);
    [shell setEnvironment:taskEnv];
    if([userShell isEqualToString:tcsh]) {
        [shell setArguments:[NSArray arrayWithObjects:@"-s",@"-",nil]];        
    } else if([userShell isEqualToString:bash]) {
        [shell setArguments:[NSArray arrayWithObjects:@"-s",@"-l",nil]];        
    }
    [shell setStandardInput:inPipe];
    [shell setStandardOutput:outPipe];
    [shell setStandardError:outPipe];
    [shell launch];

    //[self readIntoData:inData fromHandle:readHandle];
    [TCSIOUtils writeString:@"env\n" toHandle:writeHandle];
    [TCSIOUtils writeString:@"exit\n" toHandle:writeHandle];
    [TCSIOUtils readIntoData:inData fromHandle:readHandle];

    //logDebug(@"inData = %@",[[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding]);
    NSString *envString = [[[NSString alloc] 
                            initWithData:inData 
                                encoding:NSASCIIStringEncoding] autorelease];

    
    [shell release];
    
    NSArray *pairs = [envString componentsSeparatedByString:@"\n"];
    int i, pcount =  [pairs count];
    shellEnv = [[NSMutableDictionary alloc] init];
    for(i = 0; i < pcount ; i++) {
        NSString *nameAndValue = [pairs objectAtIndex:i];
        NSRange eRange = [nameAndValue rangeOfString:@"="];
        if(eRange.location != NSNotFound) {
            NSString *name = [nameAndValue substringWithRange:NSMakeRange(0,eRange.location)];
            NSString *value = [nameAndValue substringFromIndex:eRange.location+1];
            //logDebug(@"(name,value) = (%@,%@)",name,value);
            // TODO could value ever be nil?
            if(name!=nil) [shellEnv setObject:value forKey:name];
        }
    }
    //logDebug(@"shellEnv = %@",shellEnv);
    return [shellEnv autorelease];
}



@end
