//
//  TCSComponent.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/23/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSComponentProtocol.h"

@interface TCSComponent : NSObject <TCSComponentProtocol, NSCoding> {
    NSString *name;
    TCSComponent * parent;
    NSMutableArray *components;
    NSImage *icon;
    id command; //can be a number or a string depending on the dataCell displaying it
}

- (id) initWithParent:(TCSComponent *)aParent
                 name:(NSString *)aName;
+ (id) withParent:(TCSComponent *)aParent
             name:(NSString *)aName 
       components:(NSArray *)someComponents;


- (void)setCommand:(id)newCommand ;
- (void) setParent:(TCSComponent *)aParent;
- (void) setName:(NSString *)newName;
- (void) setIcon:(NSImage *)newIcon;

@end
