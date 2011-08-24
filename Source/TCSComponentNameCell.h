//
//  TCSComponentNameCell.h
//  TomcatSlapper
//
//  Created by John Clayton on 1/5/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCSComponentNameCell : NSTextFieldCell {
    NSImage	*image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
