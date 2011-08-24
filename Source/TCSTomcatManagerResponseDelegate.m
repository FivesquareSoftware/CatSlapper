//
//  TCSTomcatManagerResponseDelegate.m
//  TomcatSlapper
//
//  Created by John Clayton on 1/18/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSTomcatManagerResponseDelegate.h"
#import "TCSComponent.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import "TCSTomcatManagerAuthController.h"
#import "TCSPrefController.h"
#import "TCSIOUtils.h"
#import "TCSComponentProtocol.h"

@implementation TCSTomcatManagerResponseDelegate

// OBJECT STUFF ============================================================= //

- (id) initWithComponent:(id<TCSComponentProtocol>)aComponent {
    if([self isMemberOfClass:[TCSTomcatManagerResponseDelegate class]])
        [NSException raise:TCSExceptionSubclassMustImplement 
                    format:@"Instantiate a response delegate subclass instead."];
    if(self = [super init]) {
        component = [aComponent retain];
        //BACTRACK removed extra retain
        responseData = [[NSMutableData alloc] init];
    }
    return self;
}

+ (id) withComponent:(id<TCSComponentProtocol>)aComponent {
    return [[[[self class] alloc] initWithComponent:aComponent] autorelease];
}

- (void) dealloc {
    [component release];
    [responseData release];
    [rString release];
    [rLines release];
    [messages release];
    [super dealloc];
}

// KVC ====================================================================== //

- (TCSComponent *)component {
    return component;
}

- (void)setComponent:(TCSComponent *)newComponent {
    [newComponent retain];
    [component release];
    component = newComponent;
}

- (NSMutableData *)responseData {
    return responseData;
}

- (void)setResponseData:(NSMutableData *)newResponseData {
    [newResponseData retain];
    [responseData release];
    responseData = newResponseData;
}

- (NSString *)rString {
    return rString;
}

- (void)setRString:(NSString *)newRString {
    [newRString retain];
    [rString release];
    rString = newRString;
}

- (NSArray *)rLines {
    return rLines;
}

- (void)setRLines:(NSArray *)newRLines {
    [newRLines retain];
    [rLines release];
    rLines = newRLines;
}

- (NSMutableDictionary *)messages {
    return messages;
}

- (void)setMessages:(NSMutableDictionary *)newMessages {
    [newMessages retain];
    [messages release];
    messages = newMessages;
}



// CONNECTION DELEGATE ======================================================= //

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection 
                 willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    logTrace(@"Connection (%@) requested to use cached response (%@)",self,cachedResponse);
    return nil;
}

-(NSURLRequest *)connection:(NSURLConnection *)connection 
            willSendRequest:(NSURLRequest *)request 
           redirectResponse:(NSURLResponse *)redirectResponse {
    logTrace(@"%@ received redirect response %@, redirecting to %@",self,redirectResponse,request);
    return request;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    logDebug(@"%@ received Manager response",self);
    [responseData setLength:0]; //reset at every response
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    logTrace(@"%@ received Manager response data (%@)",self,data);
    logTrace(@"%@ received Manager response data",self);
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    ///TODO warn user that component update failed  
    NSString *errType = [NSString stringWithUTF8String:strerror([error code])];
    //TODO get a description from NSURLError.h of what the error code means
    logError(@"%@ failed with error(%@) type (%@)",self,error,errType);
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationComponentUpdateFailed 
                      object:component];
    
}

- (void)connection:(NSURLConnection *)connection 
        didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    logDebug(@"%@ received auth challenge %@", self, challenge);
    
    
    NSURLProtectionSpace *pspace = [challenge protectionSpace];
    logDebug(@"%@.challenge.protectionSpace (%@)", self,pspace); 
    logDebug(@"%@.pspace.host (%@)", self,[pspace host]); 
    logDebug(@"%@.pspace.realm (%@)", self,[pspace realm]); 
    logDebug(@"%@.pspace.protocol (%@)", self,[pspace protocol]); 
    logDebug(@"%@.pspace.port (%d)", self,[pspace port]); 
    
    logDebug(@"%@.challenge.proposedCredential (%@)", self,[challenge proposedCredential]); 
    logDebug(@"%@.challenge.failureResponse (%@)", self,[challenge failureResponse]); 
    logDebug(@"%@.challenge.previousFailureCount (%d)", self,[challenge previousFailureCount]); 
    logDebug(@"%@.challenge.error (%@)", self,[challenge error]); 

    
    BOOL shouldAuth = NO;
    // check for stored credentials
    NSURLCredential *credential = 
        [[NSURLCredentialStorage sharedCredentialStorage]
             defaultCredentialForProtectionSpace:[challenge protectionSpace]];
    if(credential != nil) {
        if([challenge previousFailureCount] < 1) {
            logDebug(@"%@ attempting authorization with stored credentials %@",self,credential);
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            shouldAuth = YES;
        }
    } else {
        shouldAuth = YES;
    }
    
    if(shouldAuth) {
        logDebug(@"%@ asking user for authentication",self);
        TCSTomcatManagerAuthController *authController = [TCSTomcatManagerAuthController sharedAuthController];
        credential = [authController authorizeForChallenge:challenge component:component];
        if(credential != nil) {
            logDebug(@"%@ attempting authorization with credentials %@",self,credential);
            logDebug(@"credential.user = %@",[credential user]);
            logDebug(@"credential.password = %@",[credential password]);
            logDebug(@"credential.persistence = %d",[credential persistence]);
            logDebug(@"credential.hasPassword = %d",[credential hasPassword]);
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
    }
    
}

- (void)connection:(NSURLConnection *)connection 
    didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    logDebug(@"Connection cancelled auth challenge (%@) for delegate %@",challenge,self);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    logDebug(@"%@ finished",self);
    [self setRString:[TCSIOUtils dataString:responseData]];
    [self setRLines:[rString componentsSeparatedByString:@"\n"]];
    messages = nil;
    if([rLines count] > 0) {
        [self setMessages:[NSMutableDictionary 
                    dictionaryWithObject:[rLines objectAtIndex:0] 
                                  forKey:TCSManagerResponseMessage]];
    }
        
    [self handleResponse];
}


- (void) handleResponse {
    [NSException raise:TCSExceptionSubclassMustImplement 
                    format:@"Instantiate a response delegate subclass instead."];
}


/* From NSURLError.h
 enum
 {
     NSURLErrorUnknown = 			-1,
     NSURLErrorCancelled = 			-999,
     NSURLErrorBadURL = 				-1000,
     NSURLErrorTimedOut = 			-1001,
     NSURLErrorUnsupportedURL = 			-1002,
     NSURLErrorCannotFindHost = 			-1003,
     NSURLErrorCannotConnectToHost = 		-1004,
     NSURLErrorNetworkConnectionLost = 		-1005,
     NSURLErrorDNSLookupFailed = 		-1006,
     NSURLErrorHTTPTooManyRedirects = 		-1007,
     NSURLErrorResourceUnavailable = 		-1008,
     NSURLErrorNotConnectedToInternet = 		-1009,
     NSURLErrorRedirectToNonExistentLocation = 	-1010,
     NSURLErrorBadServerResponse = 		-1011,
     NSURLErrorUserCancelledAuthentication = 	-1012,
     NSURLErrorUserAuthenticationRequired = 	-1013,
     NSURLErrorZeroByteResource = 		-1014,
     NSURLErrorFileDoesNotExist = 		-1100,
     NSURLErrorFileIsDirectory = 		-1101,
     NSURLErrorNoPermissionsToReadFile = 	-1102,
     NSURLErrorSecureConnectionFailed = 		-1200,
     NSURLErrorServerCertificateHasBadDate = 	-1201,
     NSURLErrorServerCertificateUntrusted = 	-1202,
     NSURLErrorServerCertificateHasUnknownRoot = -1203,
     NSURLErrorCannotLoadFromNetwork = 		-2000,
     
     // Download and file I/O errors
     NSURLErrorCannotCreateFile = 		-3000,
     NSURLErrorCannotOpenFile = 			-3001,
     NSURLErrorCannotCloseFile = 		-3002,
     NSURLErrorCannotWriteToFile = 		-3003,
     NSURLErrorCannotRemoveFile = 		-3004,
     NSURLErrorCannotMoveFile = 			-3005,
     NSURLErrorDownloadDecodingFailedMidStream = -3006,
     NSURLErrorDownloadDecodingFailedToComplete =-3007,
 };

 */

@end
