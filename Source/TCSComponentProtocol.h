//
//  TCSComponentProtocol.h
//  TomcatSlapper
//
//  Created by John Clayton on 12/22/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCSConstants.h"

@class TCSComponent;

@protocol TCSComponentProtocol <NSObject>

- (TCSComponent *) parent;
- (void) setParent:(TCSComponent *)aParent;
- (TCSComponent *) rootComponent;
- (NSString *) name;
- (NSString *) statusText;
- (NSString *) componentInfo;
- (NSString *) componentStatus;
- (NSArray *) components;
- (NSImage *) icon;
- (id) command;

- (void) updateWithComponent:(TCSComponent *)aComponent;
- (int) numberOfComponents;
- (BOOL) containsComponent:(TCSComponent *)aComponent;
- (TCSComponent *) componentWithName:(NSString *) aName;
- (int) indexOfComponent:(TCSComponent *)aComponent;
- (TCSComponent *) componentAtIndex:(int) idx;    

- (void) addComponent:(TCSComponent *)newComponent;
- (void) addComponents:(NSArray *) someComponents; 
- (void) removeComponent:(TCSComponent *)oldComponent;
- (void) replaceComponent:(TCSComponent *)oldComponent 
            withComponent:(TCSComponent *)newComponent;
- (void) updateComponent:(TCSComponent *)aComponent;

@end
