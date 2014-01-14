//
//  DividerBar.m
//  Blog Creature
//
//  Created by Dan Weber on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DividerBar.h"

#define A_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:194/255.f green:194/255.f blue:194/255.f alpha:1.0]
#define A_TOP_HIGHLIGHT_COLOR [NSColor colorWithCalibratedRed:247/255.f green:247/255.f blue:247/255.f alpha:1.0]
#define A_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]
#define A_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:232/255.f green:232/255.f blue:232/255.f alpha:1.0]

@implementation DividerBar

-(void)mouseDown:(NSEvent *)theEvent {
    NSRect  windowFrame = [[self window] frame];
    
    initialLocation = [NSEvent mouseLocation];
    
    initialLocation.x -= windowFrame.origin.x;
    initialLocation.y -= windowFrame.origin.y;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint currentLocation;
    NSPoint newOrigin;
    
    NSRect  screenFrame = [[NSScreen mainScreen] frame];
    NSRect  windowFrame = [self frame];
    
    currentLocation = [NSEvent mouseLocation];
    newOrigin.x = currentLocation.x - initialLocation.x;
    newOrigin.y = currentLocation.y - initialLocation.y;
    
    // Don't let window get dragged up under the menu bar
    if( (newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ){
        newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
    }
    
    //go ahead and move the window to the new location
    [[self window] setFrameOrigin:newOrigin];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect frame = dirtyRect;
    CGFloat s = 1.f;
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        //s = [NSScreen mainScreen].backingScaleFactor;
    }
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:A_TOP_GRADIENT_COLOR endingColor:A_BOTTOM_GRADIENT_COLOR];
    [gradient drawInRect:NSMakeRect(0, NSMinY(frame) + 1*s, NSWidth(frame), NSHeight(frame) - 3*s) angle:270.0];
    [gradient release];
    [A_TOP_BORDER_COLOR set];
    NSRectFill(NSMakeRect(0, NSMaxY(frame) - 1*s, NSWidth(frame), 1*s));
    [A_TOP_HIGHLIGHT_COLOR set];
    NSRectFill(NSMakeRect(0, NSMaxY(frame) - 2*s, NSWidth(frame), 1*s));
    [A_BOTTOM_BORDER_COLOR set];
    NSRectFill(NSMakeRect(0, NSMinY(frame), NSWidth(frame), 1*s));

    [A_TOP_BORDER_COLOR set];
    NSRectFill(NSMakeRect(NSMinX(frame) + 5*s, NSMinY(frame) + 8*s, 1*s, NSHeight(frame) - 16*s));
    NSRectFill(NSMakeRect(NSMinX(frame) + 8*s, NSMinY(frame) + 8*s, 1*s, NSHeight(frame) - 16*s));
    NSRectFill(NSMakeRect(NSMinX(frame) + 11*s, NSMinY(frame) + 8*s, 1*s, NSHeight(frame) - 16*s));
}

@end
