//
//  LSBackgroundView.m
//  Printpress
//
//  Created by Daniel Weber on 12/9/12.
//
//

#import "LSBackgroundView.h"

@implementation LSBackgroundView


- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithCalibratedWhite:232/255.f alpha:1.f] set];
    NSRectFill(self.bounds);
}

@end
