//
//  TCSIOUtils.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/16/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSIOUtils.h"
#import "TCSLogger.h"


@implementation TCSIOUtils


// READ/WRITE =============================================================== //


+ (void) writeString:(NSString *)aString toHandle:(NSFileHandle *)aWriteHandle {
    [aWriteHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (void) readIntoData:(NSMutableData *)someData fromHandle:(NSFileHandle *)aReadHandle {
    @try {
        NSData *tmpData;
        while ((tmpData = [aReadHandle availableData]) && [tmpData length]) {        
            [someData  appendData:tmpData];      
            // TODO is this string really leaking?
            //logTrace(@"tmpData = %@",[[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding]);
        }
    } @catch (NSException *e) {
        logError(@"Error reading from filehandle: %@", [e description]);
    }
}

+ (NSData *) stringData:(NSString *)aString {
    NSData *data = [aString dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}


+ (NSString *) dataString:(NSData *)someData {        
    NSString *string = @"";
    if(someData != nil)  {
        logTrace(@"someData = %@",someData);
        if([someData length] > 0) {
            // BUG: why did UTF8 encoding stop working?
            string = [[NSString alloc] 
                    initWithData:someData 
                        encoding:NSASCIIStringEncoding];
            logTrace(@"string = %@",string);
        }
    }
    return [string autorelease];
}


+ (void) _readPipe:(FILE *)aPipe {
    @try {
        char myReadBuffer[128];        
        for(;;) {
            int bytesRead = read (fileno (aPipe),
                                  myReadBuffer, sizeof (myReadBuffer));
            if (bytesRead < 1) break;
            NSString *oString = 
                [TCSIOUtils dataString:
                    [NSData dataWithBytes:myReadBuffer length:bytesRead]];
            logDebug(@"%@", oString);
        }
        fflush(aPipe);
        fclose(aPipe);
    }
    @catch (NSException * e) {
        logError(@"Error reading from pipe (%@)",[e description]);
    }
}


@end
