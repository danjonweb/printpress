//
//  FormatBarView.m
//  Sitemaker
//
//  Created by Dan Weber on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GradientView.h"

#define IN_COLOR_MAIN_START_L [NSColor colorWithDeviceWhite:0.66 alpha:1.0]
#define IN_COLOR_MAIN_END_L [NSColor colorWithDeviceWhite:0.9 alpha:1.0]
#define IN_COLOR_MAIN_BOTTOM_L [NSColor colorWithDeviceWhite:0.408 alpha:1.0]

#define IN_COLOR_NOTMAIN_START_L [NSColor colorWithDeviceWhite:0.878 alpha:1.0]
#define IN_COLOR_NOTMAIN_END_L [NSColor colorWithDeviceWhite:0.976 alpha:1.0]
#define IN_COLOR_NOTMAIN_BOTTOM_L [NSColor colorWithDeviceWhite:0.655 alpha:1.0]

@implementation GradientView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code here.
	}
	
	return self;
}

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResignKey:) name:NSWindowDidResignKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeKey:) name:NSWindowDidBecomeKeyNotification object:[self window]];
}

- (void)didResignKey:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

- (void)didBecomeKey:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

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
	if ([[self window] isKeyWindow] || [[self window] isMainWindow]) {
		/*startingColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
		endingColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
		topBorderColor = [NSColor colorWithCalibratedWhite:0.76 alpha:1.0];
		bottomBorderColor = [NSColor colorWithCalibratedWhite:0.43 alpha:1.0];*/

        startingColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
		endingColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
		topBorderColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
		bottomBorderColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];
	} else {
		/*startingColor = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
		endingColor = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
		topBorderColor = [NSColor colorWithCalibratedWhite:0.89 alpha:1.0];
		bottomBorderColor = [NSColor colorWithCalibratedWhite:0.43 alpha:1.0];*/

        startingColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
		endingColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
		topBorderColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
		bottomBorderColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];
	}
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor] autorelease];
	[gradient drawInRect:[self bounds] angle:270.0];
	[topBorderColor set];
	NSRectFill(NSMakeRect(0, NSMaxY([self bounds]) - 1, NSWidth([self bounds]), 1));
	[bottomBorderColor set];
	NSRectFill(NSMakeRect(0, 0, NSWidth([self bounds]), 1));
}

@end
