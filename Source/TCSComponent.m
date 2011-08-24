//
//  TCSComponent.m
//  TomcatSlapper
//
//  Created by John Clayton on 12/23/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSComponent.h"
#import "TCSLogger.h"


@implementation TCSComponent

// OBJECT STUFF ============================================================= //


- (id) init {
    return [self initWithParent:nil name:nil];
}

- (id) initWithParent:(TCSComponent *)aParent
                 name:(NSString *)aName {
    if(self = [super init]) {
        parent = [aParent retain]; 
        // parents can retain children in their components array so 
        // there could be an object cycle here
        name = [aName retain];
        //BACTRACK removed extra retain
        components = [[NSMutableArray alloc] init];
        icon = nil;
        command = nil;
    }
    return self;
}

+ (id)  withParent:(TCSComponent *)aParent
              name:(NSString *)aName 
        components:(NSArray *)someComponents {
    id component = [[[[self class] alloc] initWithParent:aParent name:aName] autorelease];
    [component addComponents:someComponents];
    return component;
}

- (void) updateWithComponent:(TCSComponent *)aComponent {
    [self setCommand:[aComponent command]];
    [self setIcon:[aComponent icon]];
    // this caused lots of trouble because parent was getting switched
    // when we only want data to be updated
    //[self setParent:[aComponent parent]]; //this doesn't remove me from my parent
    [self setName:[aComponent name]];
}

- (void) dealloc {
    [name release];
    [components release];
    //[statusText release];
    [command release];
    [icon release];
    [parent release];
    [super dealloc];
}


// COMPONENT PROTOCOL ======================================================= //


- (id)command {
    return command;
}

- (void)setCommand:(id)newCommand {
    [newCommand retain];
    [command release];
    command = newCommand;
}

- (NSImage *) icon {
    return icon;
}

- (void) setIcon:(NSImage *)newIcon {
    [newIcon retain];
    [icon release];
    icon = newIcon;
}

- (TCSComponent *) parent {
    return parent;
}

- (void) setParent:(TCSComponent *)aParent {
    [aParent retain];
    [parent release];
    parent = aParent;
}

- (TCSComponent *) rootComponent {
    id myRoot = self;
    id myParent = [self parent];
    while(myParent != nil) {
        myRoot = myParent;
        myParent = [myParent parent];
    }
    return myRoot;
}

- (NSString *) name {
    return name;
}

- (void) setName:(NSString *)newName {
    [newName retain];
    [name release];
    name = newName;
}

- (NSString *) statusText {
    return NSLocalizedString(@"TCSComponent.noStatusText",nil);
}

/*
- (void)setStatusText:(NSString *)newStatusText {
    [newStatusText retain];
    [statusText release];
    statusText = newStatusText;
}
*/

- (NSString *) componentInfo {
    return NSLocalizedString(@"TCSComponent.noComponentInfo",nil);
}

/*
- (void) setComponentInfo:(NSString *)newComponentInfo {
    [newComponentInfo retain];
    [componentInfo release];
    componentInfo = newComponentInfo;
}

- (void) appendToComponentInfo:(NSString *) someInfo {
    NSString *myInfo = [@"\n" stringByAppendingString:someInfo];
    if(componentInfo == nil) {
        [self setComponentInfo:myInfo];
    } else {
        [self setComponentInfo:
            [componentInfo stringByAppendingString:myInfo]];
    }
}
*/

- (NSString *)componentStatus {
    return NSLocalizedString(@"TCSComponent.noSComponentStatus",nil);
}

/*
 - (void)setComponentStatus:(NSString *)newComponentStatus {
    logTrace(@"setComponentStatus:'%@'",newComponentStatus);
    [newComponentStatus retain];
    [componentStatus release];
    componentStatus = newComponentStatus;
}

- (void) appendToComponentStatus:(NSString *) mLine {
    NSString *myMsg = [@"\n" stringByAppendingString:mLine];
    logTrace(@"appendToComponentStatus:'%@'",myMsg);
    if(componentStatus == nil) {
        [self setComponentStatus:myMsg];
    } else {
        [self setComponentStatus:
            [componentStatus stringByAppendingString:myMsg]];
    }
}
*/

- (NSArray *) components {
    return components;
}

- (int) numberOfComponents {
    return [components count];
}

- (BOOL) containsComponent:(TCSComponent *)aComponent {
    return [components containsObject:aComponent];
}

- (TCSComponent *) componentWithName:(NSString *) aName {
    TCSComponent * component = nil;
    int i;
    for(i = 0; i < [components count]; i++ ) {
        TCSComponent * thisComponent = [components objectAtIndex:i];
        if([[thisComponent name] isEqual:aName]) {
            component = thisComponent;
            break;
        }
    }
    return component;
}

- (int) indexOfComponent:(TCSComponent *)aComponent {
    return [components indexOfObject:aComponent];
}

- (TCSComponent *) componentAtIndex:(int) idx {
    return [components objectAtIndex:idx];
}

- (void) addComponent:(TCSComponent *)newComponent {
    [components addObject:newComponent];   
    [newComponent setParent:self];
}

- (void) addComponents:(NSArray *) someComponents {
    [components addObjectsFromArray:someComponents];
    int i;
    for(i = 0; i < [someComponents count];i++) {
        [[someComponents objectAtIndex:i] setParent:self];
    }
}

- (void) removeComponent:(TCSComponent *)oldComponent {
    [components removeObject:oldComponent];
}

- (void) replaceComponent:(TCSComponent *)oldComponent 
            withComponent:(TCSComponent *)newComponent {
    int idx = [components indexOfObject:oldComponent];
    [components replaceObjectAtIndex:idx withObject:newComponent];
}

- (void) updateComponent:(TCSComponent *)aComponent {
    int idx = [components indexOfObject:aComponent];
    [components replaceObjectAtIndex:idx withObject:aComponent];
    //[components removeObjectAtIndex:idx];
    //[components addObject:aComponent];
}


// NSCoding ================================================================= //

- (void) encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self name] forKey:@"TCSComponentName"];//derived in some cases
    [coder encodeObject:components forKey:@"TCSComponents"];
    [coder encodeObject:icon forKey:@"TCSIcon"];
    [coder encodeObject:parent forKey:@"TCSParent"];
}


- (id) initWithCoder:(NSCoder *)coder {
    name = [[coder decodeObjectForKey:@"TCSComponentName"] retain];
    components = [[coder decodeObjectForKey:@"TCSComponents"] retain];
    icon = [[coder decodeObjectForKey:@"TCSIcon"] retain];
    parent = [[coder decodeObjectForKey:@"TCSParent"] retain]; 

    return self;
}

@end
