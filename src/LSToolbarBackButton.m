//
//  LSToolbarBackButton.m
//  Blog Creature
//
//  Created by Daniel Weber on 10/21/12.
//
//

#import "LSToolbarBackButton.h"
#import "NSBezierPath+Stroke.h"

@implementation LSToolbarBackButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawImage:(BOOL)isAlt {
    NSRect rect = NSMakeRect(0, 0, NSWidth(self.frame), 18);

    CGFloat offset1 = 1.0;
    CGFloat offset2 = 2.0;
    CGFloat arrowWidth = 5.0;
    
    NSColor *textColor;
    NSColor *shadowColor;
    NSColor *arrowTopColor;
    NSColor *arrowMidColor;
    NSColor *arrowBottomColor;
    CGFloat alpha;
    if (isAlt) {
        alpha = 0.7;
    } else {
        alpha = 1.0;
    }
    textColor = [NSColor colorWithCalibratedWhite:0.4 alpha:alpha];
    shadowColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:alpha];
    arrowTopColor = [NSColor colorWithCalibratedWhite:(247-20)/255.f alpha:alpha];
    arrowMidColor = [NSColor colorWithCalibratedWhite:(240-40)/255.f alpha:alpha];
    arrowBottomColor =[NSColor colorWithCalibratedWhite:(232-20)/255.f alpha:alpha];

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(0, -1)];
    [shadow setShadowColor:shadowColor];
    NSDictionary *attrs = @{NSFontAttributeName : [NSFont systemFontOfSize:11.0], NSForegroundColorAttributeName : textColor, NSShadowAttributeName : shadow};
    NSSize titleSize = [self.title sizeWithAttributes:attrs];

    [self.title drawAtPoint:NSMakePoint(0, 0.5 * (NSHeight(rect) - titleSize.height)) withAttributes:attrs];

    [shadowColor set];
    NSBezierPath *shadowPath = [NSBezierPath bezierPath];
    [shadowPath moveToPoint:NSMakePoint(NSMaxX(rect) - arrowWidth - offset1, NSMaxY(rect))];
    [shadowPath lineToPoint:NSMakePoint(NSMaxX(rect) - offset1, NSMidY(rect))];
    [shadowPath lineToPoint:NSMakePoint(NSMaxX(rect) - arrowWidth - offset1, NSMinY(rect))];
    [shadowPath stroke];

    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(NSMaxX(rect) - arrowWidth - offset2, NSMaxY(rect))];
    [arrowPath lineToPoint:NSMakePoint(NSMaxX(rect) - offset2, NSMidY(rect))];
    [arrowPath lineToPoint:NSMakePoint(NSMaxX(rect) - arrowWidth - offset2, NSMinY(rect))];
    [NSGraphicsContext saveGraphicsState];
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:arrowTopColor, 0.0, arrowMidColor, 0.5, arrowBottomColor, 1.0, nil] autorelease];
    [[arrowPath strokedPath] setClip];
    [gradient drawInRect:NSInsetRect(self.bounds, 0, 0) angle:-90.f];
    [NSGraphicsContext restoreGraphicsState];
    
}

- (void)awakeFromNib {
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(NSWidth(self.bounds), NSHeight(self.bounds))] autorelease];
    NSImage *alternateImage = [[[NSImage alloc] initWithSize:NSMakeSize(NSWidth(self.bounds), NSHeight(self.bounds))] autorelease];

    [image lockFocus];
    [self drawImage:NO];
    [image unlockFocus];
    [alternateImage lockFocus];
    [self drawImage:YES];
    [alternateImage unlockFocus];
    [self setImage:image];
    [self setAlternateImage:alternateImage];
    
}

@end
