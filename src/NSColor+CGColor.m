//
//  NSColor+CGColor.m
//  Blogmator
//
//  Created by Dan Weber on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSColor+CGColor.h"

@implementation NSColor (CGColor)

- (CGColorRef)CGColor2
{
	NSColor *colorRGB = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat components[4];
	[colorRGB getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	CGColorSpaceRef theColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGColorRef theColor = CGColorCreate(theColorSpace, components);
	CGColorSpaceRelease(theColorSpace);
	return (CGColorRef)[(id)theColor autorelease];
}

+ (NSColor*)colorWithCGColor2:(CGColorRef)aColor
{
	const CGFloat *components = CGColorGetComponents(aColor);
	CGFloat red = components[0];
	CGFloat green = components[1];
	CGFloat blue = components[2];
	CGFloat alpha = components[3];
	return [self colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}

@end
