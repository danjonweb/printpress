//
//  MyWebView.m
//  Sitemaker
//
//  Created by Dan Weber on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LSWebView.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>
#import "NSColor+CGColor.h"
#import "NSColor+Hex.h"
#import "LSColorPopUpButton.h"
#import "NSBezierPath+StrokeExtensions.h"
#import "RegexKitLite.h"
#import "MediaController.h"

@interface ImageOverlayView : NSView {
	CALayer *dragLayer;
}

- (void)showPopover;
- (void)reposition;

@property (readwrite) BOOL isDragging, didDrag;
@property (readwrite) NSPoint lastDragLocation;
@property (readwrite) NSRect lastFrame;
@property (assign) LSWebView *webView;
@property (nonatomic, assign) CGFloat ratio;

@end

@implementation ImageOverlayView

const float kDragRegionSize = 20.0;

- (id)initWithFrame:(NSRect)frame webView:(LSWebView *)aWebView {
	self = [super initWithFrame:frame];
	if (self) {
		[self setWantsLayer:YES];
		
		self.layer.delegate = self;
		
		dragLayer = [CALayer layer];
		//dragLayer.backgroundColor = [NSColor colorWithDeviceRed:0.0 green:0.5 blue:0.8 alpha:1.0].CGColor2;
        dragLayer.delegate = self;
		[self.layer addSublayer:dragLayer];
		[self updateLayers];

        self.ratio = NSWidth(frame) / NSHeight(frame);
		
		self.webView = aWebView;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (BOOL)isFlipped {
	return YES;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == dragLayer) {
        if (layer.superlayer.bounds.size.width >= 20 && layer.superlayer.bounds.size.height >= 20) {
            NSGraphicsContext *nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:YES];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:nsGraphicsContext];
            
            [[NSColor colorWithDeviceRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.8] set];
            
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(NSMinX(layer.bounds), NSMaxY(layer.bounds))];
            [path lineToPoint:NSMakePoint(NSMinX(layer.bounds)+12, NSMinY(layer.bounds))];
            [path moveToPoint:NSMakePoint(NSMinX(layer.bounds)+4, NSMaxY(layer.bounds))];
            [path lineToPoint:NSMakePoint(NSMinX(layer.bounds)+16, NSMinY(layer.bounds))];
            [path moveToPoint:NSMakePoint(NSMinX(layer.bounds)+8, NSMaxY(layer.bounds))];
            [path lineToPoint:NSMakePoint(NSMinX(layer.bounds)+20, NSMinY(layer.bounds))];
            
            [path stroke];
            
            [NSGraphicsContext restoreGraphicsState];
        }
    } else {
        DOMElement *element = (DOMElement *)self.webView.imageNode;
        DOMCSSStyleDeclaration *style = [self.webView computedStyleForElement:element pseudoElement:nil];
        
        NSGraphicsContext *nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:YES];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:nsGraphicsContext];
        
        // Margin
        [[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:0.3] set];
        NSRectFill(NSMakeRect(0, 0, [[style getPropertyValue:@"margin-left"] floatValue], CGRectGetHeight(layer.bounds)));
        NSRectFill(NSMakeRect(CGRectGetWidth(layer.bounds) - [[style getPropertyValue:@"margin-right"] floatValue], 0, [[style getPropertyValue:@"margin-right"] floatValue], CGRectGetHeight(layer.bounds)));
        NSRectFill(NSMakeRect(0, 0, CGRectGetWidth(layer.bounds), [[style getPropertyValue:@"margin-top"] floatValue]));
        NSRectFill(NSMakeRect(0, CGRectGetHeight(layer.bounds) - [[style getPropertyValue:@"margin-bottom"] floatValue], CGRectGetWidth(layer.bounds), [[style getPropertyValue:@"margin-bottom"] floatValue]));
        [[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:1.0] set];
        NSRect marginRect = NSMakeRect(0, 0, NSWidth(layer.bounds), NSHeight(layer.bounds));
        NSBezierPath *marginPath = [NSBezierPath bezierPathWithRect:marginRect];
        [marginPath setLineWidth:1.0];
        [marginPath strokeInside];
        
        
        [[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:0.3] set];
        NSRect borderRect = NSMakeRect(style.marginLeft.floatValue, style.marginTop.floatValue, layer.bounds.size.width-style.marginLeft.floatValue-style.marginRight.floatValue, layer.bounds.size.height-style.marginTop.floatValue-style.marginBottom.floatValue);
        NSRectFill(borderRect);
        [[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:1.0] set];
        NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:borderRect];
        [borderPath setLineWidth:2.0];
        [borderPath strokeInside];
        
        NSRect contentRect = NSMakeRect(style.marginLeft.floatValue+style.borderLeft.floatValue+style.paddingLeft.floatValue, style.marginTop.floatValue+style.borderTop.floatValue+style.paddingTop.floatValue, layer.bounds.size.width-style.marginLeft.floatValue-style.borderLeft.floatValue-style.paddingLeft.floatValue-style.marginRight.floatValue-style.borderRight.floatValue-style.paddingRight.floatValue, layer.bounds.size.height-style.marginTop.floatValue-style.borderTop.floatValue-style.paddingTop.floatValue-style.marginBottom.floatValue-style.borderBottom.floatValue-style.paddingBottom.floatValue);
        NSBezierPath *contentPath = [NSBezierPath bezierPathWithRect:contentRect];
        CGFloat dashArray[2] = {5.0, 2.0};
        [contentPath setLineDash:dashArray count:2 phase:0];
        [contentPath setLineWidth:1.0];
        [contentPath strokeInside];
        
        
        // Border
        /*[[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:0.5] set];
         NSRectFill(NSMakeRect(style.marginLeft.floatValue, style.marginTop.floatValue, style.borderLeft.floatValue, layer.bounds.size.height-style.marginTop.floatValue-style.marginBottom.floatValue));
         NSRectFill(NSMakeRect(layer.bounds.size.width-style.marginRight.floatValue-style.borderRight.floatValue, style.marginTop.floatValue, style.borderRight.floatValue, layer.bounds.size.height-style.marginTop.floatValue-style.marginBottom.floatValue));
         NSRectFill(NSMakeRect(style.marginLeft.floatValue, style.marginTop.floatValue, layer.bounds.size.width-style.marginLeft.floatValue-style.marginRight.floatValue, style.borderTop.floatValue));
         NSRectFill(NSMakeRect(style.marginLeft.floatValue, layer.bounds.size.height-style.marginBottom.floatValue-style.borderBottom.floatValue, layer.bounds.size.width-style.marginLeft.floatValue-style.marginRight.floatValue, style.borderBottom.floatValue));
         [[NSColor colorWithDeviceRed:5/255.0 green:175/255.0 blue:234/255.0 alpha:1.0] set];
         NSRect borderRect = marginRect;
         borderRect.origin.x += [[style getPropertyValue:@"margin-left"] floatValue];
         borderRect.size.width -= [[style getPropertyValue:@"margin-left"] floatValue] + [[style getPropertyValue:@"margin-right"] floatValue];
         borderRect.origin.y += [[style getPropertyValue:@"margin-top"] floatValue];
         borderRect.size.height -= [[style getPropertyValue:@"margin-top"] floatValue] + [[style getPropertyValue:@"margin-bottom"] floatValue];
         NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:borderRect];
         [borderPath setLineWidth:2.0];
         [borderPath strokeInside];*/
        
        
        
        
        /*NSRectFill(NSMakeRect(CGRectGetWidth(layer.bounds) - [[style getPropertyValue:@"margin-right"] floatValue], 0, [[style getPropertyValue:@"margin-right"] floatValue], CGRectGetHeight(layer.bounds)));
         NSRectFill(NSMakeRect(0, 0, CGRectGetWidth(layer.bounds), [[style getPropertyValue:@"margin-top"] floatValue]));
         NSRectFill(NSMakeRect(0, CGRectGetHeight(layer.bounds) - [[style getPropertyValue:@"margin-bottom"] floatValue], CGRectGetWidth(layer.bounds), [[style getPropertyValue:@"margin-bottom"] floatValue]));
         [[NSColor colorWithDeviceRed:64/255.0 green:124/255.0 blue:152/255.0 alpha:1.0] set];
         NSRect marginRect = NSMakeRect(0, 0, NSWidth(layer.bounds), NSHeight(layer.bounds));
         NSBezierPath *marginPath = [NSBezierPath bezierPathWithRect:marginRect];
         [marginPath setLineWidth:1.0];
         [marginPath strokeInside];*/
        
        /*[[NSColor colorWithDeviceRed:27/255.0 green:201/255.0 blue:197/255.0 alpha:1.0] set];
         NSRect borderRect = marginRect;
         borderRect.origin.x += [[style getPropertyValue:@"margin-left"] floatValue];
         borderRect.size.width -= [[style getPropertyValue:@"margin-left"] floatValue] + [[style getPropertyValue:@"margin-right"] floatValue];
         borderRect.origin.y += [[style getPropertyValue:@"margin-top"] floatValue];
         borderRect.size.height -= [[style getPropertyValue:@"margin-top"] floatValue] + [[style getPropertyValue:@"margin-bottom"] floatValue];
         NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:borderRect];
         [borderPath setLineWidth:2.0];
         [borderPath strokeInside];*/
        
        
        CGFloat padding = 4.0;
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
        [shadow setShadowOffset:NSMakeSize(1.0, 1.1)];
        NSDictionary *attrs = @{NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande" size:10.0], NSForegroundColorAttributeName : [NSColor colorWithDeviceRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.8], NSShadowAttributeName : shadow};
        
        //[[NSColor whiteColor] set];
        [[NSColor colorWithDeviceRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.8] set];
        NSString *widthString = [style getPropertyValue:@"width"];
        widthString = [widthString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"px"]];
        if ([widthString integerValue] >= 60) {
            CGSize widthStringSize = [widthString sizeWithAttributes:attrs];
            
            NSInteger y = NSMinY(contentRect) + 20;
            NSRect hLine1 = NSMakeRect(contentRect.origin.x, y, (NSInteger)(contentRect.size.width / 2.0 - widthStringSize.width / 2.0), 1.0);
            NSRectFill(hLine1);
            
            [widthString drawAtPoint:NSMakePoint(NSMaxX(hLine1) + padding, (NSInteger)(NSMidY(hLine1) - widthStringSize.height / 2.0)) withAttributes:attrs];
            
            NSInteger x2 = NSMaxX(hLine1) + 2*padding + widthStringSize.width;
            NSRect hLine2 = NSMakeRect(x2, y, NSMaxX(contentRect)-x2, 1.0);
            NSRectFill(hLine2);
        }
        
        NSString *heightString = [style getPropertyValue:@"height"];
        heightString = [heightString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"px"]];
        if ([heightString integerValue] >= 60) {
            CGSize heightStringSize = [heightString sizeWithAttributes:attrs];
            
            NSInteger x = NSMinX(contentRect) + 20;
            NSRect vLine1 = NSMakeRect(x, contentRect.origin.y, 1.0, (NSInteger)(contentRect.size.height / 2.0 - heightStringSize.height / 2.0));
            NSRectFill(vLine1);
            
            [heightString drawAtPoint:NSMakePoint((NSInteger)(NSMidX(vLine1) - heightStringSize.width / 2.0), NSMaxY(vLine1) + padding) withAttributes:attrs];
            
            NSInteger y2 = NSMaxY(vLine1) + 2*padding + heightStringSize.height;
            NSRect vLine2 = NSMakeRect(x, y2, 1.0, NSMaxY(contentRect)-y2);
            NSRectFill(vLine2);
        }
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)updateLayers {
	[CATransaction begin]; 
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	NSRect dragRect = NSMakeRect(NSWidth([self bounds]) - 15, NSHeight([self bounds]) - 15, 12, 12);
	dragLayer.frame = dragRect;
    [dragLayer setNeedsDisplay];
	[CATransaction commit];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [self.webView.imagePopover close];
    NSPoint clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect dragRect = NSMakeRect(NSWidth([self bounds]) - kDragRegionSize, NSHeight([self bounds]) - kDragRegionSize, kDragRegionSize, kDragRegionSize);
	if (NSPointInRect(clickLocation, dragRect)) {
		self.isDragging = YES;
		self.lastDragLocation = clickLocation;
		self.lastFrame = [self.webView frameForNode:self.webView.imageNode];
	} else {
		self.isDragging = NO;
	}
    
	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [super mouseUp:theEvent];

    if ([theEvent clickCount] == 2) {
        DOMElement *element = (DOMElement *)self.webView.imageNode;
        [element removeAttribute:@"width"];
        [element removeAttribute:@"height"];
        [self reposition];
    } else {
        if (!self.isDragging)
            [self.webView performSelector:@selector(selectNode)];
    }
    
    /*if (!self.isDragging) {
        [self.webView hideOverlayView];
        [self showPopover];
	}*/
    
    if ([[self.webView editingDelegate] respondsToSelector:@selector(webViewDidChange:)]) {
        [[self.webView editingDelegate] performSelector:@selector(webViewDidChange:) withObject:nil];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (self.isDragging) {
		NSPoint newDragLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		CGFloat deltaX = newDragLocation.x - self.lastDragLocation.x;
		//CGFloat deltaY = newDragLocation.y - lastDragLocation.y;
		//NSRect frame = NSMakeRect(lastFrame.origin.x, lastFrame.origin.y, lastFrame.size.width + deltaX, lastFrame.size.height + deltaY);
        NSRect nodeFrame = [self.webView frameForNode:self.webView.imageNode];
        NSRect frame = NSMakeRect(nodeFrame.origin.x, nodeFrame.origin.y, self.lastFrame.size.width + deltaX, (self.lastFrame.size.width + deltaX) / self.ratio);
        

		[self setFrame:NSIntegralRect(frame)];
		[self updateLayers];

        DOMElement *element = (DOMElement *)self.webView.imageNode;
        DOMCSSStyleDeclaration *style = [self.webView computedStyleForElement:element pseudoElement:nil];
        CGFloat hPadding = 0;
        CGFloat vPadding = 0;
        hPadding += [[style getPropertyValue:@"padding-left"] floatValue];
        hPadding += [[style getPropertyValue:@"border-left"] floatValue];
        hPadding += [[style getPropertyValue:@"margin-left"] floatValue];
        hPadding += [[style getPropertyValue:@"padding-right"] floatValue];
        hPadding += [[style getPropertyValue:@"border-right"] floatValue];
        hPadding += [[style getPropertyValue:@"margin-right"] floatValue];

        vPadding += [[style getPropertyValue:@"padding-top"] floatValue];
        vPadding += [[style getPropertyValue:@"border-top"] floatValue];
        vPadding += [[style getPropertyValue:@"margin-top"] floatValue];
        vPadding += [[style getPropertyValue:@"padding-bottom"] floatValue];
        vPadding += [[style getPropertyValue:@"border-bottom"] floatValue];
        vPadding += [[style getPropertyValue:@"margin-bottom"] floatValue];
        
        [element setAttribute:@"width" value:[NSString stringWithFormat:@"%lipx", (NSInteger)(NSWidth([self frame]) - hPadding)]];
		[element setAttribute:@"height" value:[NSString stringWithFormat:@"%lipx", (NSInteger)(NSHeight([self frame]) - vPadding)]];
	} else {
		[super mouseDragged:theEvent];
	}
}

- (void)showPopover {
    [self.webView.imagePopover setBehavior:NSPopoverBehaviorTransient];
    self.webView.imagePopover.delegate = self.webView;

    [self.webView.imageBorderSegmentedControl setSelectedSegment:0];
    [self.webView borderSelected:nil];

    [self reposition];
}

- (void)reposition {
    NSRect frame = [self.webView frameForNode:self.webView.imageNode];
    [self setFrame:frame];
    [self updateLayers];

    /*DOMElement *element = (DOMElement *)self.webView.imageNode;
    DOMCSSStyleDeclaration *style = [self.webView computedStyleForElement:element pseudoElement:nil];
    
    self.webView.imageWidthField.integerValue = style.width.integerValue;
    self.webView.imageHeightField.integerValue = style.height.integerValue;
    self.webView.imageMarginTopField.integerValue = style.marginTop.integerValue;
    self.webView.imageMarginBottomField.integerValue = style.marginBottom.integerValue;
    self.webView.imageMarginRightField.integerValue = style.marginRight.integerValue;
    self.webView.imageMarginLeftField.integerValue = style.marginLeft.integerValue;


    [self.webView.imagePopover showRelativeToRect:[self.webView contentFrameForNode:self.webView.imageNode] ofView:self.webView.mainFrame.frameView.documentView preferredEdge:NSMaxYEdge];*/
}

@end

#pragma mark -

@implementation LSWebView

- (void)awakeFromNib {
	//isDocumentFrameDifferent = YES;
	//NSView *docView = [[[self mainFrame] frameView] documentView];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentViewFrameChanged:) name:NSViewFrameDidChangeNotification object:docView];
	//[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateOverlayView:) userInfo:nil repeats:YES];
    self.trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner:self userInfo:nil] autorelease];
    [self addTrackingArea:self.trackingArea];
}

- (void)dealloc {
    self.imageNode = nil;
    self.trackingArea = nil;
	[self hideOverlayView];
	[super dealloc];
}

- (void)updateTrackingAreas {
    [self removeTrackingArea:self.trackingArea];
    self.trackingArea = nil;
    self.trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner:self userInfo:nil] autorelease];
    [self addTrackingArea:self.trackingArea];
}

#pragma mark -

- (void)webViewDidChange {
    if ([[self editingDelegate] respondsToSelector:@selector(webViewDidChange:)]) {
        [[self editingDelegate] performSelector:@selector(webViewDidChange:) withObject:nil];
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    DOMElement *element = (DOMElement *)self.imageNode;

    if ([notification object] == self.imageWidthField) {
        [element setAttribute:@"width" value:[NSString stringWithFormat:@"%lipx", self.imageWidthField.integerValue]];
        [self webViewDidChange];
    }
    if ([notification object] == self.imageHeightField) {
        [element setAttribute:@"height" value:[NSString stringWithFormat:@"%lipx", self.imageHeightField.integerValue]];
        [self webViewDidChange];
    }
    if ([notification object] == self.imageMarginTopField ||
        [notification object] == self.imageMarginRightField ||
        [notification object] == self.imageMarginBottomField ||
        [notification object] == self.imageMarginLeftField) {
        NSString *marginString = @"";
        if (self.imageMarginTopField.integerValue == self.imageMarginRightField.integerValue &&
            self.imageMarginRightField.integerValue == self.imageMarginBottomField.integerValue &&
            self.imageMarginBottomField.integerValue == self.imageMarginLeftField.integerValue) {
            // All four margins are the same
            if (self.imageMarginTopField.stringValue.length > 0)
                marginString = [NSString stringWithFormat:@"%lipx", self.imageMarginTopField.integerValue];
        } else if (self.imageMarginTopField.integerValue == self.imageMarginBottomField.integerValue &&
                   self.imageMarginRightField.integerValue == self.imageMarginLeftField.integerValue) {
            // Top and bottom, right and left margins are the same
            marginString = [NSString stringWithFormat:@"%lipx %lipx", self.imageMarginTopField.integerValue, self.imageMarginRightField.integerValue];
        } else if (self.imageMarginTopField.integerValue != self.imageMarginBottomField.integerValue &&
                   self.imageMarginRightField.integerValue == self.imageMarginLeftField.integerValue) {
            // Top and bottom are different, right and left are the same
            marginString = [NSString stringWithFormat:@"%lipx %lipx %lipx", self.imageMarginTopField.integerValue, self.imageMarginRightField.integerValue, self.imageMarginBottomField.integerValue];
        } else {
            marginString = [NSString stringWithFormat:@"%lipx %lipx %lipx %lipx", self.imageMarginTopField.integerValue, self.imageMarginRightField.integerValue, self.imageMarginBottomField.integerValue, self.imageMarginLeftField.integerValue];
        }
        element.style.margin = marginString;
        [self webViewDidChange];
    }
    [imageOverlayView reposition];
    
    if ([notification object] == self.imageBorderWidthField) {
        [self borderChanged];
    }
}

- (IBAction)borderStyleSelected:(id)sender {
    [self borderChanged];
}

- (IBAction)borderColorSelected:(id)sender {
    [self borderChanged];
}

- (void)borderChanged {
    DOMElement *element = (DOMElement *)self.imageNode;

    if ([self.imageBorderSegmentedControl isSelectedForSegment:0]) {
        if (self.imageBorderWidthField.stringValue.length > 0)
            element.style.borderWidth = [NSString stringWithFormat:@"%@px", self.imageBorderWidthField.stringValue];
        if (self.imageBorderStylePopUpButton.indexOfSelectedItem >= 0)
            element.style.borderStyle = self.imageBorderStylePopUpButton.titleOfSelectedItem.lowercaseString;
        if (self.imageBorderColorPopUpButton.indexOfSelectedItem >= 0)
            element.style.borderColor = [NSString stringWithFormat:@"#%@", self.imageBorderColorPopUpButton.hexString];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:1]) {
        element.style.borderTopWidth = [NSString stringWithFormat:@"%@px", self.imageBorderWidthField.stringValue];
        element.style.borderTopStyle = self.imageBorderStylePopUpButton.titleOfSelectedItem.lowercaseString;
        element.style.borderTopColor = [NSString stringWithFormat:@"#%@", self.imageBorderColorPopUpButton.hexString];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:2]) {
        element.style.borderRightWidth = [NSString stringWithFormat:@"%@px", self.imageBorderWidthField.stringValue];
        element.style.borderRightStyle = self.imageBorderStylePopUpButton.titleOfSelectedItem.lowercaseString;
        element.style.borderRightColor = [NSString stringWithFormat:@"#%@", self.imageBorderColorPopUpButton.hexString];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:3]) {
        element.style.borderBottomWidth = [NSString stringWithFormat:@"%@px", self.imageBorderWidthField.stringValue];
        element.style.borderBottomStyle = self.imageBorderStylePopUpButton.titleOfSelectedItem.lowercaseString;
        element.style.borderBottomColor = [NSString stringWithFormat:@"#%@", self.imageBorderColorPopUpButton.hexString];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:4]) {
        element.style.borderLeftWidth = [NSString stringWithFormat:@"%@px", self.imageBorderWidthField.stringValue];
        element.style.borderLeftStyle = self.imageBorderStylePopUpButton.titleOfSelectedItem.lowercaseString;
        element.style.borderLeftColor = [NSString stringWithFormat:@"#%@", self.imageBorderColorPopUpButton.hexString];
    }

    [imageOverlayView reposition];
    [self webViewDidChange];
}

- (IBAction)borderSelected:(id)sender {
    DOMElement *element = (DOMElement *)self.imageNode;
    DOMCSSStyleDeclaration *style = [self computedStyleForElement:element pseudoElement:nil];

    [self.imageBorderStylePopUpButton selectItemAtIndex:-1];
    [self.imageBorderColorPopUpButton clearColor];
    [self.imageBorderWidthField setStringValue:@""];

    if ([self.imageBorderSegmentedControl isSelectedForSegment:0]) {
        if ([style.borderStyle componentsSeparatedByString:@" "].count == 1)
            [self.imageBorderStylePopUpButton selectItemWithTitle:style.borderStyle.capitalizedString];
        if ([style.borderColor componentsMatchedByRegex:@"rgb(.*?)"].count == 1)
            [self.imageBorderColorPopUpButton selectRGBColorString:style.borderColor];
        if ([style.borderWidth componentsSeparatedByString:@" "].count == 1)
            [self.imageBorderWidthField setIntegerValue:style.borderWidth.integerValue];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:1]) {
        [self.imageBorderStylePopUpButton selectItemWithTitle:style.borderTopStyle.capitalizedString];
        [self.imageBorderColorPopUpButton selectRGBColorString:style.borderTopColor];
        [self.imageBorderWidthField setIntegerValue:style.borderTopWidth.integerValue];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:2]) {
        [self.imageBorderStylePopUpButton selectItemWithTitle:style.borderRightStyle.capitalizedString];
        [self.imageBorderColorPopUpButton selectRGBColorString:style.borderRightColor];
        [self.imageBorderWidthField setIntegerValue:style.borderRightWidth.integerValue];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:3]) {
        [self.imageBorderStylePopUpButton selectItemWithTitle:style.borderBottomStyle.capitalizedString];
        [self.imageBorderColorPopUpButton selectRGBColorString:style.borderBottomColor];
        [self.imageBorderWidthField setIntegerValue:style.borderBottomWidth.integerValue];
    } else if ([self.imageBorderSegmentedControl isSelectedForSegment:4]) {
        [self.imageBorderStylePopUpButton selectItemWithTitle:style.borderLeftStyle.capitalizedString];
        [self.imageBorderColorPopUpButton selectRGBColorString:style.borderLeftColor];
        [self.imageBorderWidthField setIntegerValue:style.borderLeftWidth.integerValue];
    }
}

#pragma mark -

- (void)showOverlayViewWithFrame:(NSRect)frame forNode:(DOMNode *)node {
	NSView *docView = [[[self mainFrame] frameView] documentView];
	[imageOverlayView removeFromSuperview];
	imageOverlayView = nil;
	imageOverlayView = [[[ImageOverlayView alloc] initWithFrame:frame webView:self] autorelease];
	[imageOverlayView setWantsLayer:YES];
	[[docView superview] addSubview:imageOverlayView positioned:NSWindowAbove relativeTo:docView];
}

- (void)hideOverlayView {
	[imageOverlayView removeFromSuperview];
	imageOverlayView = nil;
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSArray* urls = [[sender draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    
    NSURL *url = urls[0];
    if ([self.mediaController.imageExtensions containsObject:url.pathExtension]) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	// Read image URLs
    /*[[sender draggingPasteboard] ]
	NSArray* urls = [[sender draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    
    NSURL *url = urls[0];
    if ([self.mediaController.imageExtensions containsObject:url.pathExtension]) {
        NSString *fileName = [[url absoluteString] lastPathComponent];
        NSString *path = [self.dataManager.localMediaFolder stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
            [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:path] error:nil];
            [self replaceSelectionWithMarkupString:[NSString stringWithFormat:@"<img src=\"%@\">", path]];
            return YES;
        } else {
            NSLog(@"not readable");
        }
    }
    return NO;*/
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSURL *originURL = [NSURL URLFromPasteboard:pboard];
        
        NSString *fileName = [[originURL absoluteString] lastPathComponent];
        NSString *path = [self.dataManager.localMediaFolder stringByAppendingPathComponent:fileName];
        NSURL *destURL = [NSURL fileURLWithPath:path];
        
        [[NSFileManager defaultManager] copyItemAtURL:originURL toURL:destURL error:nil];
        [self replaceSelectionWithMarkupString:[NSString stringWithFormat:@"<img src=\"%@\">", path]];
        return YES;
        
    }
    
    return NO;
	
	// Let webview perform the default drop
	//[super performDragOperation:sender];
	
	// Replace selected URLs text with images 
	
}

- (NSRect)contentFrameForNode:(DOMNode *)node {
    DOMElement *element = (DOMElement *)node;
    DOMCSSStyleDeclaration *style = [self computedStyleForElement:element pseudoElement:nil];
    NSRect nodeFrame = [self frameForNode:node];
    NSRect contentRect = NSMakeRect(NSMinX(nodeFrame)+style.marginLeft.floatValue+style.borderLeft.floatValue+style.paddingLeft.floatValue, NSMinY(nodeFrame)+style.marginTop.floatValue+style.borderTop.floatValue+style.paddingTop.floatValue, nodeFrame.size.width-style.marginLeft.floatValue-style.borderLeft.floatValue-style.paddingLeft.floatValue-style.marginRight.floatValue-style.borderRight.floatValue-style.paddingRight.floatValue, nodeFrame.size.height-style.marginTop.floatValue-style.borderTop.floatValue-style.paddingTop.floatValue-style.marginBottom.floatValue-style.borderBottom.floatValue-style.paddingBottom.floatValue);
    return contentRect;
}

- (NSRect)frameForNode:(DOMNode *)node {
    NSRect frame = [node boundingBox];
    
    DOMElement *element = (DOMElement *)node;
    DOMCSSStyleDeclaration *style = [self computedStyleForElement:element pseudoElement:nil];
    CGFloat left = [[style getPropertyValue:@"margin-left"] floatValue];
    CGFloat right = [[style getPropertyValue:@"margin-right"] floatValue];
    CGFloat top = [[style getPropertyValue:@"margin-top"] floatValue];
    CGFloat bottom = [[style getPropertyValue:@"margin-bottom"] floatValue];

    frame.origin.x -= left;
    frame.size.width += (left + right);
    frame.origin.y -= top;
    frame.size.height += (top + bottom);

    return frame;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    DOMNode *node = [elementInformation objectForKey:WebElementDOMNodeKey];
	if (node) {
		if ([[node nodeName] isEqualToString:@"IMG"]) {
			//NSRect bounds = [node boundingBox];
            if (self.imageNode != node) {
                self.imageNode = node;
                [self hideOverlayView];
                [self showOverlayViewWithFrame:[self frameForNode:node] forNode:node];
            } else {
                if (!imageOverlayView) {
                    [self showOverlayViewWithFrame:[self frameForNode:node] forNode:node];
                }
            }
			
		} else {
            if (!self.imagePopover.shown)
                [self hideOverlayView];
		}
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self hideOverlayView];
}

- (void)selectNode {
    DOMDocument *domDoc = [[self mainFrame] DOMDocument];
	DOMRange *domRange = [domDoc createRange];
	[domRange selectNode:self.imageNode];
	[self setSelectedDOMRange:domRange affinity:NSSelectionAffinityDownstream];
}

- (void)popoverDidClose:(NSNotification *)notification {
    [self selectNode];
}

- (void)updateOverlays {
    [imageOverlayView reposition];
}

@end
