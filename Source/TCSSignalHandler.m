//
//  TCSSignalHandler.m
//  TomcatSlapper
//
//  Created by John Clayton on 11/22/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSSignalHandler.h"
#import "TCSConstants.h"
#import "TCSLogger.h"
#import <mach/mach.h>

static mach_msg_header_t machMessageHeader;
static TCSSignalHandler *handler;

void _signalHandler(int sig) 
{
    mach_msg_return_t retCode = 0;
    
    machMessageHeader.msgh_id = sig;
    retCode = mach_msg_send(&machMessageHeader);
    if (retCode != 0) {
        logDebug(@"mach_msg_send failed in signal handler!");
    }
}

@implementation TCSSignalHandler

+ (void) installSignalHandler {
    //we never call release on this statically allocated instance
    handler = [[TCSSignalHandler alloc] init];
    
    signal(SIGINT, _signalHandler);
    signal(SIGTERM, _signalHandler);
}


- (id) init {
    if(self = [super init]) {

        NSMachPort *receivePort = [[NSMachPort alloc] init];
        [receivePort setDelegate:self];
        [receivePort scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        // Construct the Mach message to be sent from
        // the signal handler function
        bzero(&machMessageHeader,sizeof(machMessageHeader));
        machMessageHeader.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0);
        machMessageHeader.msgh_size = sizeof(machMessageHeader);
        machMessageHeader.msgh_remote_port = [receivePort machPort];
        machMessageHeader.msgh_local_port = MACH_PORT_NULL;
        machMessageHeader.msgh_id = 0;
        
    }
    return self;
}

- (void) handleMachMessage:(void *)machMessage {
    mach_msg_header_t *msg = machMessage;
    int signo = msg->msgh_id;
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCSNotifcationSignalCaught 
                      object:[NSNumber numberWithInt:signo]];
}


@end
