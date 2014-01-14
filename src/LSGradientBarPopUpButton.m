//
//  LSGradientBarPopUpButton.m
//  Printpress
//
//  Created by Dan Weber on 5/11/13.
//
//

#import "LSGradientBarPopUpButton.h"

#define A_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:194/255.f green:194/255.f blue:194/255.f alpha:1.0]
#define A_TOP_HIGHLIGHT_COLOR [NSColor colorWithCalibratedRed:247/255.f green:247/255.f blue:247/255.f alpha:1.0]
#define A_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]

@implementation LSGradientBarPopUpButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    isInside = YES;
    [self setNeedsDisplay:YES];
    [super mouseDown:theEvent];
    isInside = NO;
    [self setNeedsDisplay:YES];

    return;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSInteger s = 1;
    NSRect frame = [self bounds];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:A_TOP_GRADIENT_COLOR endingColor:A_BOTTOM_GRADIENT_COLOR];
    [gradient drawInRect:NSMakeRect(0, NSMinY(frame) + 1*s, NSWidth(frame), NSHeight(frame) - 3*s) angle:270.0];
    [gradient release];
    [A_TOP_BORDER_COLOR set];
    NSRectFill(NSMakeRect(0, NSMaxY(frame) - 1*s, NSWidth(frame), 1*s));
    [A_TOP_HIGHLIGHT_COLOR set];
    NSRectFill(NSMakeRect(0, NSMaxY(frame) - 2*s, NSWidth(frame), 1*s));
    [A_BOTTOM_BORDER_COLOR set];
    NSRectFill(NSMakeRect(0, NSMinY(frame), NSWidth(frame), 1*s));
    
    CGFloat fraction;
    if (self.isEnabled) {
        if (isInside) {
            fraction = 1.0;
        } else {
            fraction = 0.6;
        }
    } else {
        fraction = 0.3;
    }
    
    NSSize imageSize = self.image.size;
    CGFloat ratio = imageSize.width/imageSize.height;
    imageSize.width = 16.0;
    imageSize.height = (int)(imageSize.width / ratio);
    
    [self.image drawAtPoint:NSMakePoint(0, 0.5*(NSMaxY(self.bounds) - self.image.size.height)-1) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
    //[self.image drawInRect:NSIntegralRect(NSMakeRect(0, 0.5*(NSMaxY(self.bounds) - imageSize.height), imageSize.width, imageSize.height)) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
    
    CGFloat rightMargin = 0.0;
    CGFloat arrowWidth = 5.0;
    [[NSColor colorWithCalibratedWhite:0.0 alpha:fraction] set];
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMaxX(self.bounds)-arrowWidth-rightMargin, NSMidY(self.bounds), arrowWidth, 1.0)];
    [p appendBezierPathWithRect:NSMakeRect(NSMaxX(self.bounds)-arrowWidth-rightMargin+1, NSMidY(self.bounds)-1, arrowWidth - 2, 1.0)];
    [p appendBezierPathWithRect:NSMakeRect(NSMaxX(self.bounds)-arrowWidth-rightMargin+2, NSMidY(self.bounds)-2, arrowWidth - 4, 1.0)];
    [p fill];
}

@end
