//
//  TCSNoPopupSelectionTransformer.m
//  TomcatSlapper
//
//  Created by John Clayton on 9/24/04.
//  Copyright 2004 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSNoPopupSelectionTransformer.h"
#import "TCSLogger.h"

@implementation TCSNoPopupSelectionTransformer


+ (Class) transformedValueClass {
    return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation {    
    return YES;   
}

/**
 * Returns YES if value is >= than 0 and not -1 (as an unsigned int)
 **/
- (id) transformedValue:(id)value {
    BOOL noSelection = YES;
    
    if(value == nil) return nil;    
    
    if([value respondsToSelector:@selector(intValue)]) {
        int iVal = [value intValue];
        logDebug(@"value = %d",iVal);
        if(iVal >= 0 && iVal != TCS_NO_SELECTION) noSelection = NO;
    } else {
        [NSException 
            raise:NSInternalInconsistencyException 
           format:@"Value (%@) does not respond to selector -intValue",[value class]
        ];
    }
    logDebug(@"noSelection = %d",noSelection);
    return [NSNumber numberWithBool:noSelection];
}

/**
 * Returns YES if value is less than 1
 **/
- (id) reverseTransformedValue:(id)value {
    logDebug( @"reversed" );
    return [NSNumber numberWithBool:([[self transformedValue:value] boolValue] && NO)];
}


@end
