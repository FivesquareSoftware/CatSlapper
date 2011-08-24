//
//  TCSLogger.h
//  TomcatSlapper
//
//  Created by John Clayton on 9/29/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOG_OFF  99
#define LOG_FATAL  50
#define LOG_ERROR  40
#define LOG_WARN  30
#define LOG_INFO  20
#define LOG_DEBUG  10
#define LOG_TRACE  0

#ifndef LOG_LEVEL
#define LOG_LEVEL LOG_FATAL
#endif

#define NO_LINE_NUMBER -1


#define TCS_LOCATION lineNumber: __LINE__ fileName: __FILE__ methodName: __PRETTY_FUNCTION__

#define logTrace(format, args...) [TCSLogger trace:format TCS_LOCATION , ## args]
#define logDebug(format, args...) [TCSLogger debug:format TCS_LOCATION , ## args]
#define logInfo(format, args...) [TCSLogger info:format TCS_LOCATION , ## args]
#define logWarn(format, args...) [TCSLogger warn:format TCS_LOCATION , ## args]
#define logError(format, args...) [TCSLogger error:format TCS_LOCATION , ## args]
#define logFatal(format, args...) [TCSLogger fatal:format TCS_LOCATION , ## args] 


@interface TCSLogger : NSObject {
}


+ (void) trace:(NSString *)aFormat,...;
+ (void) debug:(NSString *)aFormat,...;
+ (void) info:(NSString *)aFormat,...;
+ (void) warn:(NSString *)aFormat,...;
+ (void) error:(NSString *)aFormat,...;
+ (void) fatal:(NSString *)aFormat,...;

+ (void) trace: (id) aFormat
  lineNumber: (int) lineNumber
    fileName: (char *) fileName
  methodName: (const char *) methodName,...;

+ (void) debug: (id) aFormat
    lineNumber: (int) lineNumber
      fileName: (char *) fileName
    methodName: (const char *) methodName,...;

+ (void) info: (id) aFormat
   lineNumber: (int) lineNumber
     fileName: (char *) fileName
   methodName: (const char *) methodName,...;

+ (void) warn: (id) aFormat
   lineNumber: (int) lineNumber
     fileName: (char *) fileName
   methodName: (const char *) methodName,...;

+ (void) error: (id) aFormat
    lineNumber: (int) lineNumber
      fileName: (char *) fileName
    methodName: (const char *) methodName,...;

+ (void) fatal: (id) aFormat
    lineNumber: (int) lineNumber
      fileName: (char *) fileName
    methodName: (const char *) methodName,...;

//private
+ (void) _logMsg:(NSString *)logMsg 
      lineNumber: (int) lineNumber
        fileName: (char *) fileName
      methodName: (const char *) methodName
         message: (id) aFormat;    


@end
