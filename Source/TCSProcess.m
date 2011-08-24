//
//  TCSProcess.m
//  TomcatSlapper
//
//  Created by John Clayton on 5/20/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//


#define DAY_SECONDS (24 * 60 * 60)
#define HOUR_SECONDS (60 * 60)
#define MINUTE_SECONDS 60

#import "TCSProcess.h"
#import "TCSProcess+Private.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import <AGRegex/AGRegex.h>

@implementation TCSProcess

static NSString *ps = @"/bin/ps";
static NSArray *infoOpts;
static NSArray *forPidOpts;
static NSString *headerPattern  = @"(\\s*PID\\s*)(UCOMM\\s*)(STARTED\\s*)(COMMAND\\s*)";

+ (void) initialize {
    //TODO will these leak if we don't release?
    infoOpts = [[NSArray arrayWithObjects:@"axeww",@"-opid,ucomm,lstart,command",nil] retain];
    forPidOpts= [[NSArray arrayWithObjects:@"eww",@"-opid,ucomm,lstart,command",@"-p",nil] retain];
}

// STATIC METHODS =========================================================== //

+ (NSArray *) allProcesses {
    return nil;
}

+ (NSArray *) processesForCommand:(NSString *)aCommand {
    logDebug(@"processesForCommand:%@",aCommand);
    NSMutableArray *matchingProcesses = nil;
    NSString *psout = [TCSProcess _psWithArguments:infoOpts];
    if(psout != nil) {
        NSArray *processes = [TCSProcess _processes:psout];
        matchingProcesses = [[[NSMutableArray alloc] init] autorelease];
        int i, pcount = [processes count];
        for(i = 0; i < pcount; i++) {
            TCSProcess *process = [processes objectAtIndex:i];
            if([[process ucomm] isEqualToString:aCommand])
                [matchingProcesses addObject:process];
        }
    }
    return matchingProcesses;
}

+ (TCSProcess *) processForProcessIdentifier:(int)aPid {
    logDebug(@"processForProcessIdentifier:%d",aPid);
    TCSProcess *process = nil;
    if(aPid > 0) {
        NSMutableArray *myOpts = [[[NSMutableArray alloc] init] autorelease];
        [myOpts addObjectsFromArray:forPidOpts];
        [myOpts addObject:[[NSNumber numberWithInt:aPid] stringValue]];
        logDebug(@"running ps");
        NSString *psout = [TCSProcess _psWithArguments:myOpts];
        if(psout != nil) {
            logTrace(@"parsing processes");        
            NSArray *processes = [TCSProcess _processes:psout];
            logTrace(@"getting process for pid (%d)", aPid);        
            if([processes count] > 0) {
                //this is only retained by the array which is autoreleased already
                process = [processes objectAtIndex:0];
                logTrace(@"got it (%d)",[process processIdentifier]);        
            }
        }
    }
    return process;
}



// OBJECT STUFF ============================================================= //

- (id) initWithProcessIdentifier:(int)aPid {
    if(self = [super init]) {
        processIdentifier = aPid;
    }
    return self;
}

- (void) dealloc {
    [startTime release];
    [fullCommand release];
    [arguments release];
    [environment release];
    [super dealloc];
}

- (NSString *) description {
    NSString *desc = [super description];
    desc = 
        [desc stringByAppendingFormat:
            @" { pid = %d, ucomm = %@, startTime = %@, fullCommand = %@, arguments = %@, environment = %@ }"
            ,[self processIdentifier], [self ucomm], [self startTime], [self fullCommand]
            , [self arguments], [self environment] ];
    return desc;
}

- (BOOL) isEqualToString:(id)object {
    return(processIdentifier == [(TCSProcess *)object processIdentifier]);
}

// DERIVED =================================================================== //

- (NSString *) runningTime {
    NSString *rTime = nil;
    @try {
        NSTimeInterval runningInterval = 
        [[NSDate date] timeIntervalSinceDate:[self startTime]];
        // convert interval to days, hours, minutes seconds
        int runningDays = 0;
        int runningHours = 0;
        int runningMinutes = 0;
        int runningSeconds = (int)runningInterval;
        int remainderSeconds = runningSeconds;
        
        if(runningSeconds > DAY_SECONDS) {
            runningDays = runningSeconds/DAY_SECONDS;
            remainderSeconds = (runningSeconds % DAY_SECONDS);
            runningSeconds = remainderSeconds;
        }
        if(runningSeconds > HOUR_SECONDS) {
            runningHours = runningSeconds/HOUR_SECONDS;
            remainderSeconds = (runningSeconds & HOUR_SECONDS);
            runningSeconds = remainderSeconds;
        }
        if(remainderSeconds > MINUTE_SECONDS) {
            runningMinutes = runningSeconds/MINUTE_SECONDS;
            remainderSeconds = (runningSeconds % MINUTE_SECONDS);
            runningSeconds = remainderSeconds;
        }
        NSString *uptimeFormat = NSLocalizedString(@"TCSProcess.uptime",nil);
        rTime =  [NSString stringWithFormat:uptimeFormat
            ,runningDays,(runningDays==1 ? @"" : @"s"),runningHours
            ,runningMinutes,runningSeconds];
    } @catch (NSException *e) {
        logError(@"Error calculating running time: %@",e);
    } 
    return rTime;
}


// KVC ====================================================================== //

#pragma mark KVC

- (int)processIdentifier {
    return processIdentifier;
}

- (void)setProcessIdentifier:(int)newPid {
    processIdentifier = newPid;
}

- (NSString *)ucomm {
    return ucomm;
}

- (void)setUcomm:(NSString *)newUcomm {
    [newUcomm retain];
    [ucomm release];
    ucomm = newUcomm;
}

- (NSDate *)startTime {
    return startTime;
}

- (void)setStartTime:(NSDate *)newStartTime {
    [newStartTime retain];
    [startTime release];
    startTime = newStartTime;
}

- (NSString *)fullCommand {
    return fullCommand;
}

- (void)setFullCommand:(NSString *)newFullCommand {
    [newFullCommand retain];
    [fullCommand release];
    fullCommand = newFullCommand;
}

- (NSMutableArray *)arguments {
    return arguments;
}

- (void)setArguments:(NSMutableArray *)newArguments {
    [newArguments retain];
    [arguments release];
    arguments = newArguments;
}

- (NSMutableDictionary *)environment {
    return environment;
}

- (void)setEnvironment:(NSMutableDictionary *)newEnvironment {
    [newEnvironment retain];
    [environment release];
    environment = newEnvironment;
}

@end


@implementation TCSProcess (Private)

+ (NSString *) _psWithArguments:(NSArray *)args {
    NSPipe *outPipe = [[NSPipe alloc]  init];
    // we have seen problems getting a pipe before
    if(outPipe == nil) {
        logError(@"Could not create pipe for _ps: (%s)",strerror(errno));
        return nil;
    }
    NSString *psout = nil;    
    @try {
        NSTask *_ps = [[NSTask alloc] init];
        NSFileHandle *_psout = [outPipe fileHandleForReading];
        NSMutableData *inData = [NSMutableData data];
        
        [_ps setLaunchPath:ps];
        [_ps setArguments:args];
        
        logTrace(@"%@ %@",ps,args);
    
        [_ps setStandardOutput:outPipe];
        [_ps setStandardError:outPipe];

        [_ps launch];

        [TCSIOUtils readIntoData:inData fromHandle:_psout];
        psout = [TCSIOUtils dataString:inData];
        logTrace(@"psout = %@",psout);

        [_ps waitUntilExit];
        int status = [_ps terminationStatus];
        if(status) {
            logError(@"_ps did not exit clean: %d",status);
            //TODO alert user of an error condition
        }
        logTrace(@"_ps done");
        [outPipe release];
        [_ps release];
    } @catch (NSException * e) {
        logError(@"Error setting stdout for _ps (%@)",[e description]);
        return nil;
    }
    //[pool release];
    return psout;
}

+ (NSArray *) _processes:(NSString *)psout {
    // we create a lot of temp strings in here
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    logTrace(@"process psout");

    AGRegex *headerRegex = [AGRegex regexWithPattern:headerPattern];
    NSArray *psArray = [psout componentsSeparatedByString:@"\n"];
    NSString *header = [psArray objectAtIndex:0];
    AGRegexMatch *headerMatch = [headerRegex findInString:header];
    
    //TODO catch these exceptions and alert user
    NSAssert(headerMatch != nil, @"Can't read header from 'ps'");
    NSAssert([headerMatch count]==5,@"Header from 'ps' has wrong number of columns");
    
    logTrace(@"PID = '%@'",[headerMatch groupAtIndex:1]);
    logTrace(@"UCOMM = '%@'",[headerMatch groupAtIndex:2]);
    logTrace(@"STARTED = '%@'",[headerMatch groupAtIndex:3]);
    logTrace(@"COMMAND = '%@'",[headerMatch groupAtIndex:4]);
    
    int headerLength = [header length];
    
    logTrace(@"header.length = %d",headerLength);
    
    int col1length = [[headerMatch groupAtIndex:1] length];
    int col2length = [[headerMatch groupAtIndex:2] length];
    int col3length = [[headerMatch groupAtIndex:3] length];
    int col4length = [[headerMatch groupAtIndex:4] length];
    
    logTrace(@"col1length = %d",col1length);
    logTrace(@"col2length = %d",col2length);
    logTrace(@"col3length = %d",col3length);
    logTrace(@"col4length = %d",col4length);
    
    NSRange pidRange = [headerMatch rangeAtIndex:1];
    logTrace(@"pidRange.location,pidRange.length = (%d,%d)"
             ,pidRange.location,pidRange.length);
    
    NSRange ucommRange = [headerMatch rangeAtIndex:2];
    logTrace(@"ucommRange.location,ucommRange.length = (%d,%d)"
             ,ucommRange.location,ucommRange.length);
    
    NSRange startedRange = [headerMatch rangeAtIndex:3];
    logTrace(@"startedRange.location,startedRange.length = (%d,%d)"
             ,startedRange.location,startedRange.length);
    
    NSRange commandRange;
    
    NSMutableArray *processes = [[NSMutableArray alloc] init];
    int i,pcount = [psArray count];
    for(i = 1; i < pcount; i++) {
        NSString *psLine = [psArray objectAtIndex:i];
        if(psLine == nil || [psLine isEqualToString:@""]) continue;
        
        logTrace(@"psLine = '%@'",psLine);
        logTrace(@"psLine.length = %d",[psLine length]);
        
        commandRange = NSMakeRange((startedRange.location+startedRange.length)
                                   ,[psLine length]-(startedRange.location+startedRange.length));
        logTrace(@"commandRange.location,commandRange.length = (%d,%d)"
                 ,commandRange.location,commandRange.length);
        
        NSString *pidSlice = [psLine substringWithRange:pidRange];
        NSString *myPid = [pidSlice
                            stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceCharacterSet]];
        logTrace(@"myPid = '%@'",myPid);
        
        TCSProcess *process = 
            [[[TCSProcess alloc] 
                    initWithProcessIdentifier:[myPid intValue]] autorelease];
        
        NSString *ucommSlice = [psLine substringWithRange:ucommRange];
        NSString *myUcomm = [ucommSlice
                                stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
        logTrace(@"myUcomm = '%@'",myUcomm);
        [process setUcomm:myUcomm];
        
        NSString *startedSlice = [psLine substringWithRange:startedRange];
        NSString *started = [startedSlice
                                stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
        logTrace(@"started = '%@'",started);
        [process setStartTime:[NSDate dateWithNaturalLanguageString:started]];
        
        NSString *commandSlice = [psLine substringWithRange:commandRange];
        NSString *command = [commandSlice
                                stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
        logTrace(@"command = '%@'",command);
        [TCSProcess _parse:command intoProcess:process];
        
        [processes addObject:process];
    }
    //release our temp objects
    [pool release];
    
    logTrace(@"processed");
    return [processes autorelease];        
}


+ (void) _parse:(NSString *)commandAndArgsString intoProcess:(TCSProcess *)process {
    logTrace(@"_parse:%@ intoProcess:%@",commandAndArgsString,process);
    logTrace(@"parsing arg string into process (%d)",[process processIdentifier]);
    
    NSScanner *scanner = [NSScanner scannerWithString:commandAndArgsString];
    [scanner setCaseSensitive:YES];
    NSString *commPath = nil;
    NSString *commString = nil;
    
    logTrace(@"ucomm = '%@'",[process ucomm]);
    
    if([commandAndArgsString rangeOfString:[process ucomm]].location != NSNotFound) {
        BOOL found = 
            [scanner scanUpToString:[process ucomm] intoString:&commPath];
        logTrace(@"commPath = '%@'",commPath);
        logTrace(@"found = %d",found);
        if(found) {
            commString = [commPath stringByAppendingString:[process ucomm]];
        } else {
            commString = [process ucomm];
        } 
    } else {
        logWarn(@"Cannot find command in commandAndArgsString");
        return;
    }
    logTrace(@"commString = %@",commString);
    
    [process setFullCommand:commString];
    
    NSRange commRange = [commandAndArgsString rangeOfString:commString];
    NSString *argsSlice = 
        [commandAndArgsString substringFromIndex:(commRange.location+commRange.length)];
    NSString *argsString = 
        [argsSlice stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    logTrace(@"argsString = %@",argsString);
    
    if(argsString != nil && ![argsString isEqualToString:@""]) {
        NSArray *args = [argsString componentsSeparatedByString:@" "]; 
        NSMutableArray *tmpArgs = [[[NSMutableArray alloc] init] autorelease];
        NSMutableDictionary *tmpEnv = [[[NSMutableDictionary alloc] init] autorelease];
        int i;
        for(i = 0; i < [args count]; i++) {
            NSString *arg = [args objectAtIndex:i];
            logTrace(@"arg = %@",arg);
            int idx = [arg rangeOfString:@"="].location;
            if(idx != NSNotFound && [arg rangeOfString:@"-"].location != 0) {
                int start = ([arg rangeOfString:@"\""].location == 0 ? 1 : 0);
                int end = ([arg characterAtIndex:[arg length]-1] == '"'
                            ? ([arg length]-1)
                            : [arg length]);
                logTrace(@"arg.length = %d",[arg length]);
                logTrace(@"start,end = (%d,%d)",start,end);
                NSString *key = [arg substringWithRange:NSMakeRange(start,idx)];
                NSString *value = [arg substringWithRange:NSMakeRange(idx+1,(end-(idx+1)))];
                logTrace( (@"(key=value),(%@=%@)"),(key),(value) );
                @try {
                    [tmpEnv setObject:value forKey:key];
                } @catch (NSException *e) {
                    logFatal(@"Error inserting key into process environment: %@",[e description]);
                }
            } else {
                [tmpArgs addObject:arg];
            }
        }
        [process setArguments:tmpArgs];
        [process setEnvironment:tmpEnv];
    }
    logTrace(@"populated process = %@",process);
    logTrace(@"parsed arg string into process (%d)",[process processIdentifier]);
}

@end
