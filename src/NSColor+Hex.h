//
//  NSColor+Hex.h
//  Blogmator
//
//  Created by Dan Weber on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Hex)
+ (NSColor *)colorFromHexRGB:(NSString *) inColorString;
- (NSString *)hexString;
@end
