//
//  NSColor+CGColor.h
//  Blogmator
//
//  Created by Dan Weber on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (CGColor)
- (CGColorRef)CGColor2;
+ (NSColor*)colorWithCGColor2:(CGColorRef)aColor;
@property (readonly) CGColorRef CGColor2;
@end
