//
//  LSGradientBarButton.m
//  Printpress
//
//  Created by Daniel Weber on 12/16/12.
//
//

#import "LSGradientBarButton.h"


#define A_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:194/255.f green:194/255.f blue:194/255.f alpha:1.0]
#define A_TOP_HIGHLIGHT_COLOR [NSColor colorWithCalibratedRed:247/255.f green:247/255.f blue:247/255.f alpha:1.0]
#define A_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]

@implementation LSGradientBarButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        isInside = NO;
    }
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    BOOL keepOn = YES;
    isInside = YES;
    NSPoint mouseLoc;
    [self setNeedsDisplay:YES];

    while (keepOn) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        isInside = [self mouse:mouseLoc inRect:[self bounds]];

        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                [self setNeedsDisplay:YES];
                break;
            case NSLeftMouseUp:
                if (isInside) [super mouseDown:theEvent];
                isInside = NO;
                [self setNeedsDisplay:YES];
                keepOn = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        }

    };

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
    [self.image drawAtPoint:NSMakePoint(0.5*(NSMaxX(self.bounds) - self.image.size.width), 0.5*(NSMaxY(self.bounds) - self.image.size.height)) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
}

@end
