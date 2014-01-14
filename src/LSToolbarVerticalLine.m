//
//  LSVerticalLine.m
//  Blog Creature
//
//  Created by Daniel Weber on 8/15/12.
//
//

#import "LSToolbarVerticalLine.h"

@implementation LSToolbarVerticalLine

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#define START_COLOR [NSColor colorWithCalibratedWhite:202.f/255.f alpha:1.f]
#define MID_COLOR [NSColor colorWithCalibratedWhite:113.f/255.f alpha:1.f]
#define END_COLOR [NSColor colorWithCalibratedWhite:167.f/255.f alpha:1.f]

#define SHADOW_START_COLOR [NSColor colorWithCalibratedWhite:206.f/255.f alpha:1.f]
#define SHADOW_MID_COLOR [NSColor colorWithCalibratedWhite:231.f/255.f alpha:1.f]
#define SHADOW_END_COLOR [NSColor colorWithCalibratedWhite:188.f/255.f alpha:1.f]

- (void)drawRect:(NSRect)dirtyRect
{
    NSInteger midX = NSMidX(self.bounds);
    NSInteger minY = NSMinY(self.bounds);
    NSInteger height = NSHeight(self.bounds);
    CGFloat locations[3] = {0.0, 0.5, 1.0};
    NSGradient *gradient = [[[NSGradient alloc] initWithColors:@[ START_COLOR, MID_COLOR, END_COLOR ] atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]] autorelease];
    [gradient drawInRect:NSMakeRect(midX, minY, 1.f, height) angle:-90.f];

    NSGradient *shadowGradient = [[[NSGradient alloc] initWithColors:@[ SHADOW_START_COLOR, SHADOW_MID_COLOR, SHADOW_END_COLOR ] atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]] autorelease];
    [shadowGradient drawInRect:NSMakeRect(midX + 1, minY, 1.f, height) angle:-90.f];

}

@end
