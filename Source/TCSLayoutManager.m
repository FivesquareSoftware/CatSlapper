//
//  TCSLayoutManager.m
//  TomcatSlapper
//
//  Created by John Clayton on 8/17/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSLayoutManager.h"
#import "TCSLogger.h"
#import "TCSConstants.h"
#import "TCSPrefController.h"

@implementation TCSLayoutManager

- (NSDictionary *)temporaryAttributesAtCharacterIndex:(unsigned)charIndex 
                                       effectiveRange:(NSRangePointer)effectiveCharRange {
    logTrace(@"temporaryAttributesAtCharacterIndex");
    NSDictionary *dict = 
        [super temporaryAttributesAtCharacterIndex:charIndex effectiveRange:effectiveCharRange];
    logTrace(@"temporaryAttributes = %@",dict);
    NSMutableDictionary *atts  = [dict mutableCopy];
    NSArray *keys = [atts allKeys]; 
    unsigned int i, count = [keys count];
    for (i = 0; i < count; i++) {
            NSString *key = [keys objectAtIndex:i];
        if([key isEqualToString:TCSTemporaryAttributeName]) {
            NSColor *attValue = 
                [[TCSPrefController sharedPrefController] 
                    colorForAttribute:[atts objectForKey:key]];
            [atts setObject:attValue forKey:NSForegroundColorAttributeName];
        }
    }
    return [atts autorelease];
}

/*
- (void)addTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)charRange {
    logDebug(@"addTemporaryAttributes:%@",attrs);
    [super addTemporaryAttributes:attrs forCharacterRange:charRange];
}

- (void)setTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)charRange {
    logDebug(@"setTemporaryAttributes:%@",attrs);
    [super setTemporaryAttributes:attrs forCharacterRange:charRange];
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin {
    logDebug(@"drawGlyphsForGlyphRange");
    [super drawGlyphsForGlyphRange:glyphRange atPoint:containerOrigin];
}

- (void)setTextStorage:(NSTextStorage *)textStorage {
    logDebug(@"setTextStorage");
    [super setTextStorage:textStorage];
}

- (void)replaceTextStorage:(NSTextStorage *)textStorage {
    logDebug(@"replaceTextStorage");
    [super replaceTextStorage:textStorage];
}
*/

@end
