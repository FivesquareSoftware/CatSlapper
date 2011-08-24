//
//  TCSLogger.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/29/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSLogger.h"
#import "TCSConstants.h"
#import "TCSIOUtils.h"


@implementation TCSLogger

static NSFileHandle *outHandle;

+ (void) initialize {
    outHandle = [NSFileHandle fileHandleWithStandardError];
#ifdef DEBUG
    NSLog(@"TCSLogger.Logging at: %d",LOG_LEVEL);
#endif

}
// SIMPLE =================================================================== //

+ (void) trace:(NSString *)aFormat,... {
    if(LOG_TRACE >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[TRACE]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

+ (void) debug:(NSString *)aFormat,... {
    if(LOG_DEBUG >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[DEBUG]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

+ (void) info:(NSString *)aFormat,... {
    if(LOG_INFO >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[INFO]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

+ (void) warn:(NSString *)aFormat,... {
    if(LOG_WARN >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[WARN]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

+ (void) error:(NSString *)aFormat,... {
    if(LOG_ERROR >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[ERROR]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

+ (void) fatal:(NSString *)aFormat,... {
    if(LOG_FATAL >= LOG_LEVEL) {
        va_list args;
        va_start(args,aFormat);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[FATAL]" lineNumber:NO_LINE_NUMBER fileName:nil methodName:nil message:msg];
    }
}

// VERBOSE =================================================================== //


+ (void) trace: (id) aFormat 
  lineNumber: (int) lineNumber
    fileName: (char *) fileName
  methodName: (const char *) methodName,... {
    if(LOG_TRACE >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[TRACE]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}

+ (void) debug: (id) aFormat
         lineNumber: (int) lineNumber
           fileName: (char *) fileName
         methodName: (const char *) methodName,... {
    if(LOG_DEBUG >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[DEBUG]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}

+ (void) info: (id) aFormat
         lineNumber: (int) lineNumber
           fileName: (char *) fileName
         methodName: (const char *) methodName,... {
    if(LOG_INFO >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[INFO]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}

+ (void) warn: (id) aFormat
         lineNumber: (int) lineNumber
           fileName: (char *) fileName
         methodName: (const char *) methodName,... {
    if(LOG_WARN >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[WARN]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}

+ (void) error: (id) aFormat
         lineNumber: (int) lineNumber
           fileName: (char *) fileName
         methodName: (const char *) methodName,... {
    if(LOG_ERROR >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[ERROR]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}

+ (void) fatal: (id) aFormat
         lineNumber: (int) lineNumber
           fileName: (char *) fileName
         methodName: (const char *) methodName,... {
    if(LOG_FATAL >= LOG_LEVEL) {
        va_list args;
        va_start(args,methodName);
        NSString *msg = [[NSString alloc] initWithFormat:aFormat arguments:args];
        va_end(args);        
        [self _logMsg:@"[FATAL]" lineNumber:lineNumber fileName:fileName methodName:methodName message:msg];
    }
}



+ (void) _logMsg:(NSString *)logMsg 
      lineNumber: (int) lineNumber
        fileName: (char *) fileName
      methodName: (const char *) methodName
           message: (id) aMessage {
    
    NSString *myMsg;
    if([aMessage isKindOfClass:[NSString class]]) {
        myMsg = (NSString *)aMessage;
    } else if (aMessage != nil) {
        myMsg = [aMessage description];
    } else {
        myMsg = @"";
    }

    logMsg = [logMsg stringByAppendingString:@" - "];

    if(fileName != nil) {
        NSString *fileNameString = (NSString *)[NSString stringWithUTF8String:fileName];
        NSString *lastFilePathComponent = [fileNameString lastPathComponent];
        logMsg = [logMsg stringByAppendingString:lastFilePathComponent];
    }
    if(lineNumber != NO_LINE_NUMBER) {
        logMsg = [logMsg stringByAppendingString:@":"];
        logMsg = [logMsg stringByAppendingString:[NSString stringWithFormat:@"%d",lineNumber]];
    }
    if(methodName != nil) {
        logMsg = [logMsg stringByAppendingString:@" "];
        logMsg = [logMsg stringByAppendingString:[NSString stringWithUTF8String:methodName]];
    }
    logMsg = [logMsg stringByAppendingString:@" - "];
    logMsg = [logMsg stringByAppendingString:myMsg];
    logMsg = [logMsg stringByAppendingString:@"\n"];

    NSData *outData = [TCSIOUtils stringData:logMsg];
    @try {
        @synchronized (outHandle) {
            [outHandle writeData:outData];
        }
    } @catch (NSException *e) {
        //nothing, logging shouldn't crash app
    }
}

@end
