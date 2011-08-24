//
//  TCSIOUtils.h
//  TomcatSlapper
//
//  Created by John Clayton on 11/16/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSIOUtils : NSObject {

}

+ (void) writeString:(NSString *)aString toHandle:(NSFileHandle *)aWriteHandle;
+ (void) readIntoData:(NSMutableData *)someData fromHandle:(NSFileHandle *)aReadHandle;
+ (NSData *) stringData:(NSString *)aString;
+ (NSString *) dataString:(NSData *)someData;
+ (void) _readPipe:(FILE *)aPipe;

@end
