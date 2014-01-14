//
//  LSTextFieldCell.m
//  Printpress
//
//  Created by Daniel Weber on 12/2/12.
//
//

#import "LSTextFieldCell.h"
/*
#define A_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:130/255.f green:156/255.f blue:192/255.f alpha:1.0]
#define A_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:139/255.f green:167/255.f blue:205/255.f alpha:1.0]
#define A_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:103/255.f green:133/255.f blue:174/255.f alpha:1.0]
#define A_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:95/255.f green:124/255.f blue:161/255.f alpha:1.0]
 */

#define A_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:76/255.f green:145/255.f blue:215/255.f alpha:1.0]
#define A_TOP_HIGHLIGHT_COLOR [NSColor colorWithCalibratedRed:96/255.f green:170/255.f blue:229/255.f alpha:1.0]
#define A_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:89/255.f green:160/255.f blue:223/255.f alpha:1.0]
#define A_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:43/255.f green:114/255.f blue:201/255.f alpha:1.0]
#define A_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:40/255.f green:101/255.f blue:181/255.f alpha:1.0]

#define IA_TOP_BORDER_COLOR [NSColor colorWithCalibratedRed:173/255.f green:184/255.f blue:206/255.f alpha:1.0]
#define IA_TOP_HIGHLIGHT_COLOR [NSColor colorWithCalibratedRed:182/255.f green:192/255.f blue:217/255.f alpha:1.0]
#define IA_TOP_GRADIENT_COLOR [NSColor colorWithCalibratedRed:175/255.f green:185/255.f blue:213/255.f alpha:1.0]
#define IA_BOTTOM_GRADIENT_COLOR [NSColor colorWithCalibratedRed:138/255.f green:152/255.f blue:185/255.f alpha:1.0]
#define IA_BOTTOM_BORDER_COLOR [NSColor colorWithCalibratedRed:129/255.f green:142/255.f blue:171/255.f alpha:1.0]

@implementation LSTextFieldCell


- (void)drawGroupItem {
    self.isGroupItem = YES;
}

- (void)drawNormalItem {
    self.isGroupItem = NO;
}

- (void)drawIndented {
    self.isIndented = YES;
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    CGFloat s = 1.f;
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        //s = [NSScreen mainScreen].backingScaleFactor;
    }

    NSColor *topGradientColor;
    NSColor *bottomGradientColor;
    NSColor *topBorderColor;
    NSColor *bottomBorderColor;
    NSColor *topHighlightColor;
    if ([[controlView window] firstResponder] == controlView && [NSApp isActive]) {
        topGradientColor = A_TOP_GRADIENT_COLOR;
        bottomGradientColor = A_BOTTOM_GRADIENT_COLOR;
        topBorderColor = A_TOP_BORDER_COLOR;
        bottomBorderColor = A_BOTTOM_BORDER_COLOR;
        topHighlightColor = A_TOP_HIGHLIGHT_COLOR;
    } else {
        topGradientColor = IA_TOP_GRADIENT_COLOR;
        bottomGradientColor = IA_BOTTOM_GRADIENT_COLOR;
        topBorderColor = IA_TOP_BORDER_COLOR;
        bottomBorderColor = IA_BOTTOM_BORDER_COLOR;
        topHighlightColor = IA_TOP_HIGHLIGHT_COLOR;
    }

    cellFrame.size.width = controlView.bounds.size.width;
    
    NSDictionary *attrs;
    NSDictionary *previousAttrs;
    CGFloat X_LEFT_MARGIN = 7;
    if (self.isIndented)
        X_LEFT_MARGIN = 15;
    
    NSMutableParagraphStyle *pStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    if ([self isHighlighted]) {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topGradientColor endingColor:bottomGradientColor];
        [gradient drawInRect:NSMakeRect(0, NSMinY(cellFrame) + 2*s, NSWidth(cellFrame) + 3*s, NSHeight(cellFrame) - 3*s) angle:90.0];
        [gradient release];
        [topBorderColor set];
        NSRectFill(NSMakeRect(0, NSMinY(cellFrame), NSWidth(cellFrame), 1*s));
        [topHighlightColor set];
        NSRectFill(NSMakeRect(0, NSMinY(cellFrame) + 1*s, NSWidth(cellFrame), 1*s));
        [bottomBorderColor set];
        NSRectFill(NSMakeRect(0, NSMaxY(cellFrame)-1*s, NSWidth(cellFrame), 1*s));
        attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:15.0], NSForegroundColorAttributeName: [NSColor whiteColor], NSParagraphStyleAttributeName: pStyle};
        previousAttrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:12.0], NSForegroundColorAttributeName: [NSColor whiteColor], NSParagraphStyleAttributeName: pStyle};
    } else {
        attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Light" size:15.0], NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.2 alpha:1.0], NSParagraphStyleAttributeName: pStyle};
        previousAttrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:12.0], NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.4 alpha:1.0], NSParagraphStyleAttributeName: pStyle};
    }
    if (self.isGroupItem) {
        X_LEFT_MARGIN = 7;
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        shadow.shadowOffset = NSMakeSize(0, -1.0);
        shadow.shadowColor = [NSColor whiteColor];
        self.title = [self.title uppercaseString];
        attrs = @{NSFontAttributeName:[NSFont fontWithName:@"Helvetica-Light" size:12.0], NSForegroundColorAttributeName:[NSColor disabledControlTextColor], NSKernAttributeName:@.8, NSShadowAttributeName:shadow};
    }
    
    NSMutableAttributedString *titleAttrString = [[NSMutableAttributedString alloc] initWithString:self.title attributes:attrs];
    if (self.previousTitle.length > 0 && ![self.title isEqualToString:self.previousTitle]) {
        // Add previous title to title string
        NSAttributedString *prevTitleAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" → %@", self.previousTitle] attributes:previousAttrs];
        [titleAttrString appendAttributedString:prevTitleAttrString];
        [prevTitleAttrString release];
    }
    
    NSSize titleSize = titleAttrString.size;
    [titleAttrString drawInRect:NSMakeRect(X_LEFT_MARGIN, (int)(NSMinY(cellFrame) + 0.5*(NSHeight(cellFrame)-titleSize.height)), NSWidth(cellFrame)-2*X_LEFT_MARGIN, titleSize.height)];
    [titleAttrString release];
}

@end
