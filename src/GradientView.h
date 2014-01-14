//
//  FormatBarView.h
//  Sitemaker
//
//  Created by Dan Weber on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GradientView : NSView {
	NSColor *startingColor;
	NSColor *endingColor;
	NSColor *topBorderColor;
	NSColor *bottomBorderColor;
    NSPoint initialLocation;
}

@end
