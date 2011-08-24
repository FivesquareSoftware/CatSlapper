//
//  TCSTomcatManagerResponseDelegate.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCSComponent;
@protocol TCSComponentProtocol;

@protocol TCSTomcatManagerResponseDelegateProtocol
- (void) handleResponse;
@end

@interface TCSTomcatManagerResponseDelegate 
: NSObject <TCSTomcatManagerResponseDelegateProtocol> {
    TCSComponent *component;

    NSMutableData *responseData;
    NSString *rString;
    NSArray *rLines;
    NSMutableDictionary *messages;
}

- (id) initWithComponent:(id<TCSComponentProtocol>)tk;
+ (id) withComponent:(id<TCSComponentProtocol>)tk;

- (TCSComponent *)component;
- (void)setComponent:(TCSComponent *)newComponent;
- (NSMutableData *)responseData;
- (void)setResponseData:(NSMutableData *)newResponseData;
- (NSString *)rString;
- (void)setRString:(NSString *)newRString;
- (NSArray *)rLines;
- (void)setRLines:(NSArray *)newRLines;
- (NSMutableDictionary *)messages;
- (void)setMessages:(NSMutableDictionary *)newMessages;

@end
