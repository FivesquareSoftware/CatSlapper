//
//  TCSConsoleView.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/1/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSConsoleView.h"
#import "TCSConsoleServer.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSIOUtils.h"
#import "TCSPrefController.h"
#import "TCSLayoutManager.h"


@implementation TCSConsoleView


// OBJECT STUFF ============================================================= //

- (void) awakeFromNib {
    logDebug(@"awakeFromNib");
    [self registerObservations];
    [self setBackgroundColor:[[TCSPrefController sharedPrefController] backgroundColor]];
//    [self resetFontFromDefaults];
    [self setNeedsDisplay:YES];
}

- (id) initWithCoder:(NSCoder *)coder {
    logDebug(@"initWithCoder:");
    if(self = [super initWithCoder:coder]) {
        //BACTRACK removed extra retains
        consoleServers = [[NSMutableDictionary alloc] init];
        pendingServers = [[NSMutableArray alloc] init];
        runningServers = [[NSMutableArray alloc] init];
        stoppedServers = [[NSMutableArray alloc] init];
        textStorageByFile = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self removeObservations];
    [consoleServers release];
    [pendingServers release];
    [runningServers release];
    [stoppedServers release];
    [textStorageByFile release];
    [super dealloc];
}


// VIEW METHODS ========================================================= //
#pragma mark View Methods

- (void) createConsoleServer:(NSString *)filename {
    logDebug(@"createConsoleServer: %@",filename);

    if(filename == nil) return; // empty file bad

    NSString *fixedFilename = [self resolveFileName:filename];
    logDebug(@"resolved filename: %@",fixedFilename);
    
    logDebug(@"server exists: %d",([consoleServers objectForKey:fixedFilename] != nil));    
    if([consoleServers objectForKey:fixedFilename] != nil) return; //no dupes
    logDebug(@"server pending: %d",[pendingServers containsObject:fixedFilename]);
    if([pendingServers containsObject:fixedFilename]) return; //already started
    [pendingServers addObject:fixedFilename];
    
    // create storage
    [self addTextStorage:[self createTextStorage]
          forFixedFilename:fixedFilename];
    logTrace(@"self.textStorageForKey:%@ = %@"
             ,fixedFilename
             ,[ self textStorageForKey:fixedFilename]);

        
    NSPort *rcvPort = [NSPort port];
    NSPort *sendPort = [NSPort port];
    NSDictionary *argArray = [NSDictionary dictionaryWithObjectsAndKeys:fixedFilename
        , TCSConsoleServerArgFilename
        , rcvPort
        , TCSConsoleServerArgRcvPort
        , sendPort
        , TCSConsoleServerArgSendPort
        ,nil];


    NSConnection *clientConnection = [[NSConnection alloc]
        initWithReceivePort:rcvPort sendPort:sendPort];
    [clientConnection setRootObject:self];
    [clientConnection enableMultipleThreads];
    
    [NSThread detachNewThreadSelector:@selector(connectForFileWithPorts:) 
                             toTarget:[TCSConsoleServer class] 
                           withObject:argArray];    
}

- (NSTextStorage *) createTextStorage {
    NSTextStorage *storage = [[NSTextStorage alloc] init] ;
    TCSLayoutManager *lm = [[[TCSLayoutManager alloc] init] autorelease];
    [storage addLayoutManager:lm];
    return [storage autorelease];
    /*
    [lm release];
    NSSize conSize = [[self textContainer] containerSize];
    NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:conSize];
    [container setWidthTracksTextView:YES];
    [container setHeightTracksTextView:NO];
    [lm addTextStorage:container];
    [container release];
    return container;
    */
}

- (void) addTextStorage:(NSTextStorage *)textStorage 
         forFixedFilename:(NSString *)fixedFilename {
    if(fixedFilename != nil && ![fixedFilename isEqualToString:@""]) {
        [textStorageByFile setObject:textStorage
                                  forKey:fixedFilename];
    }
}

- (NSTextStorage *) textStorageForKey:(NSString *)filename {
    return [textStorageByFile objectForKey:filename];
}

- (TCSLayoutManager *) layoutManagerForKey:(NSString *)filename {
    NSTextStorage *storage = [self textStorageForKey:filename];
    TCSLayoutManager *lm = nil;
    if(storage != nil) {
        NSArray *managers = [storage layoutManagers];
        if([managers count] > 0)
            lm = [managers objectAtIndex:0];
    }
    return lm;
}

- (id) serverForKey:(NSString *)filename {
    return [consoleServers objectForKey:filename];
}

- (NSDictionary *) consoleServersCopy {
    return [NSDictionary dictionaryWithDictionary:consoleServers];
}

- (NSArray *) filenames {
    return [consoleServers allKeys];
}

- (void) startServer:(NSString *)filename {
    id server = [consoleServers objectForKey:filename];
    if(server != nil) {
        [server tail];
        [runningServers addObject:server];
        [stoppedServers removeObject:server];
    }
}

- (void) destroyServer:(NSString *)filename {
    NSString *fixedFilename = [self resolveFileName:filename];
    if([consoleServers objectForKey:fixedFilename] != nil) {
        [self terminateServer:filename forced:YES];
        id server = [consoleServers objectForKey:fixedFilename];
        [consoleServers removeObjectForKey:fixedFilename];
        [pendingServers removeObject:server];
        [runningServers removeObject:server];
        [stoppedServers removeObject:server];
        [textStorageByFile removeObjectForKey:fixedFilename];
        server = nil;
    }
}

- (void) terminateServer:(NSString *)filename {
    [self terminateServer:filename forced:NO];
}

- (void) terminateServer:(NSString *)filename forced:(BOOL)forced {
    NSString *fixedFilename = [self resolveFileName:filename];
    id <TCSConsoleServerMethods> server = [consoleServers objectForKey:fixedFilename];
    if(server != nil) [server terminate:forced];
}

- (void) terminateServers:(NSArray *)filenames {
    int i;
    for(i = 0; i < [filenames count]; i++) {
        [self terminateServer:[filenames objectAtIndex:i]];
    }
}

- (void) terminateAllServers:(BOOL)forced {
    logDebug(@"terminateAllServers");
    int s;
    for(s = 0; s < [runningServers count]; s++) {
        id server = [runningServers objectAtIndex:s];
        [(id <TCSConsoleServerMethods> )server terminate:forced];
    }
}

- (NSString *) activeFile {
    logTrace(@"activeFile: %@",activeFile);
    return activeFile;
}

- (void)setActiveFile:(NSString *)filename {
    logDebug(@"setActiveFile:%@",filename);
    NSString *fixedFilename = [self resolveFileName:filename];
    if(![fixedFilename isEqualToString:activeFile]) {
        [fixedFilename retain];
        [activeFile release];
        activeFile = fixedFilename;
        [self activateTextStorageFor:activeFile];
    }
}

- (void) activateTextStorageFor:(NSString *)filename {
    logDebug(@"activateTextStorageFor:%@",filename);
    
    logDebug(@"self.textStorage = %@",[[self textStorage] description]);
    logDebug(@"self.layoutManager = %@",[[self layoutManager] description]);
//    logDebug(@"self.textStorage.length = %d",[[self textStorage] length]);
    
    NSString *fixedFilename = [self resolveFileName:filename];
    NSTextStorage *storage = 
        [self textStorageForKey:[self resolveFileName:filename]];
    TCSLayoutManager *lm;
    logDebug(@"textStorageByFile.objectForKey:%@ = %@",fixedFilename,storage);
    if(storage == nil) {
        storage = [self createTextStorage];
        [self addTextStorage:storage forFixedFilename:fixedFilename];
    }
    lm = [[storage layoutManagers] objectAtIndex:0];
    
    [lm addTextContainer:[self textContainer]]; //makes the connections in container
    logDebug(@"self.textStorage = %@",[[self textStorage] description]);
    logDebug(@"self.layoutManager = %@",[[self layoutManager] description]);
//    logDebug(@"self.textStorage.length = %d",[[self textStorage] length]);
    
    [self resetFontFromDefaults:storage];    
    [self scrollToEnd:storage];
    [self setNeedsDisplay:YES];
}


//calls a synchronized method
- (void) appendString:(NSString *)someText 
              forFile:(NSString *)filename {
    [self appendString:someText
             forFile:filename
                type:TCS_STDOUT];
}

//calls a synchronized method
- (void) appendString:(NSString *)someText 
              forFile:(NSString *)filename 
                 type:(int)type {
    logTrace(@"appendString:%@ forFile:%@ type: %d",someText,filename,type);
    [self appendData:[TCSIOUtils stringData:someText] 
             forFile:[self resolveFileName:filename]
                type:type];
}

- (void) clear {
    //can be called by the main thread
    @synchronized(self) {
        NSTextStorage *storage = [self textStorage];
        NSRange all = NSMakeRange(0,[storage length]);
        [storage deleteCharactersInRange:all];
    }
}

- (int) runningServerCount {
    return [runningServers count];
}

- (int) stoppedServerCount {
    return [stoppedServers count];
}


- (NSString *) resolveFileName:(NSString *)filename {
    logDebug(@"resolveFileName:%@",filename);
    NSString *fixedFilename = [filename stringByExpandingTildeInPath];
    fixedFilename = [fixedFilename stringByResolvingSymlinksInPath];
    return fixedFilename;
}

- (void) resetFontFromDefaults:(NSTextStorage *)storage {
    if(storage == nil || [storage length] < 1) return;
    //can be called from main or DO thread
    @synchronized(storage) {
        NSFont *cfont = [[TCSPrefController sharedPrefController] consoleFont];
        logDebug(@"resetFontFromDefaults:%@",cfont);
        [self setFont:cfont];
    }
}

- (void) scrollToEnd:(NSTextStorage *)storage {
    if(storage == nil || [storage length] < 1) return;
    //can be called from main or DO thread
    @try {
        @synchronized(storage) {
            NSRange vRange = NSMakeRange([storage length]-1,1);
            logDebug(@"storage.length = %d",[storage length]);
            logDebug(@"scrollRangeToVisible:%d,%d",vRange.location,vRange.length);
            logDebug(@"self.string.length: %d",[[self string] length]);
            [self scrollRangeToVisible:vRange];    
        }
    } @catch (NSException *e) {
        logError(@"Error scrolling to end (%@)",[e description]);
    }
}

// CLIENT PROTOCOL METHODS ================================================== //
#pragma mark Client Protocol Methods

- (void) addServer:(id)newServer forFilename:(in bycopy NSString *)filename {
    logDebug(@"addServer:%@ forFilename:%@",newServer,filename);
    logTrace(@"existing server = %@",[consoleServers objectForKey:filename]);
    //if([consoleServers objectForKey:filename] != nil) {
        //[newServer terminate];
    //    return;
    //}
    [newServer setProtocolForProxy:@protocol(TCSConsoleServerMethods)];
    [consoleServers setObject:newServer forKey:filename];
    [pendingServers removeObject:filename];
    [stoppedServers addObject:newServer];
    [newServer tail];
}

- (oneway void) serverLaunched:(id)newServer {
    logDebug(@"serverLaunched:%@",newServer);
    [runningServers addObject:newServer];
    [stoppedServers removeObject:newServer];
}

- (oneway void) appendData:(in bycopy NSData *)data 
                       forFile:(in bycopy NSString *)filename
                      type:(in bycopy int)type {
    logTrace(@"appendData:%@ forFile:%@ type:%d",data,filename,type);
    logDebug(@"appendData forFile:%@",filename);

    NSString *string = [[[NSString alloc] 
                            initWithData:data 
                                encoding:NSUTF8StringEncoding] autorelease];
    if(data != nil && [data length] > 0) {
        NSMutableAttributedString *attString = 
            [[[NSMutableAttributedString alloc] initWithString:string] autorelease];
        NSString *attValue = 
            [[TCSPrefController sharedPrefController] attributeForOutputType:type];
        NSDictionary *atts = 
            [NSDictionary dictionaryWithObject:attValue forKey:TCSTemporaryAttributeName];

        NSTextStorage *storage = [self textStorageForKey:filename];
        logTrace(@"storage = %@",storage);
        logTrace(@"storage.layoutManagers[0] = %@",[[storage layoutManagers] objectAtIndex:0]);
        
        if(storage != nil) {
//            TCSLayoutManager *lm = [self layoutManagerForKey:filename];
            TCSLayoutManager *lm = [[storage layoutManagers] objectAtIndex:0];
            logTrace(@"lm = %@",lm);
            //the main thread might want to interlope here, so sync storage access
            @synchronized(storage) {
                logDebug(@"Testing for overflow");
                @try {
                    int overflow = [storage length] > LOG_FILE_MAX_STORAGE;
                    if(overflow > 0) {
                        logDebug(@"truncateStorage: %d",overflow);   
                        [storage deleteCharactersInRange:NSMakeRange(0,overflow)];
                        [storage fixAttributesInRange:NSMakeRange(0,[storage length])];
                    }

                    int start = [storage length];
                    int length = [attString length] - 1;
                    NSRange tempAttRange = NSMakeRange(start,length);
                    logDebug(@"Appending and setting temporary attributes");
                    logTrace(@"appendAttributedString: %@",attString);    
                    [storage appendAttributedString:attString];
                    logTrace(@"addTemporaryAttributes:%@",atts);    
                    [lm addTemporaryAttributes:atts 
                             forCharacterRange:tempAttRange];
            
                    logDebug(@"Fixing attributes");    
                    NSRange fixRange = NSMakeRange(0,[storage length]);
                    [storage fixAttributesInRange:fixRange];
                } @catch (NSException *e) {
                    logError(@"Error appending to text storage %@ for %@ (%@)",storage,filename,[e description]);
                }
            }
            if([[self activeFile] isEqualToString:filename]) {
                [self scrollToEnd:storage];
                [self resetFontFromDefaults:storage];
                [self setNeedsDisplay:YES];
            }
        }
    }
}

- (void) didTerminateFor:(id)server withStatus:(in bycopy int)status {   
    logDebug(@"didTerminate");
    [stoppedServers addObject:server];
    [runningServers removeObject:server];
}


// OBSERVATIONS ============================================================= //
#pragma mark Observations

- (void) registerObservations {
    [[TCSPrefController sharedPrefController] 
        addObserver:self
         forKeyPath:@"backgroundColor" 
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
    [[TCSPrefController sharedPrefController] 
        addObserver:self
         forKeyPath:@"stdoutColor" 
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
    [[TCSPrefController sharedPrefController] 
        addObserver:self
         forKeyPath:@"stderrColor" 
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
    [[TCSPrefController sharedPrefController] 
        addObserver:self
         forKeyPath:@"serverLogColor" 
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
    [[TCSPrefController sharedPrefController] 
        addObserver:self
         forKeyPath:@"consoleFont" 
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
}

- (void) removeObservations {
    [[TCSPrefController sharedPrefController] 
        removeObserver:self 
            forKeyPath:@"backgroundColor"];  
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    if([keyPath isEqualToString:@"backgroundColor"]) {
        NSColor *bgColor = [[TCSPrefController sharedPrefController] backgroundColor];
        [self setBackgroundColor:bgColor];
//        logDebug(@"superview.superview: %@",[[self superview] superview]);
//        [(NSScrollView *)[[self superview] superview] setBackgroundColor:bgColor];
    } else if([keyPath isEqualToString:@"stdoutColor"]
              || [keyPath isEqualToString:@"stderrColor"] 
              || [keyPath isEqualToString:@"serverLogColor"]) {
        [self setNeedsDisplay:YES];
    } else if([keyPath isEqualToString:@"consoleFont"]) {
        [self resetFontFromDefaults:[self textStorage]];    
    }
}


@end
