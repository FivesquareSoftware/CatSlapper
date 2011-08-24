//
//  TCSAuthorizationHandler.h
//  TomcatSlapper
//
//  Created by John Clayton on 6/28/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>
#import "TCSAuthorizationHandlerVerifiedSums.h"



@interface TCSAuthorizationHandler : NSObject {
    AuthorizationRef authRef;
}

+ (id) sharedAuthHandler;
- (BOOL) isAuthorized;
- (AuthorizationRef) authorization;
- (void) deauthorize;
- (void) alertUser:(OSStatus)status;

@end

OSStatus runVerifiedTool(AuthorizationRef authorization,
                         const char *pathToTool,
                         AuthorizationFlags options,
                         char * const *arguments,
                         FILE **communicationsPipe, 
                         const char *sum);
OSStatus verified(const char *pathToTool, const char *sum);
