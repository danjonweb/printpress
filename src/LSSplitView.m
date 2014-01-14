//
//  LSSplitView.m
//  Printpress
//
//  Created by Daniel Weber on 12/8/12.
//
//

#import "LSSplitView.h"

@implementation LSSplitView

- (void)drawDividerInRect:(NSRect)rect {
    [[NSColor colorWithCalibratedWhite:194/255.f alpha:1.0] set];
    NSRectFill(rect);
}

@end
