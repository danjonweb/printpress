//
//  LSPopUpButton.m
//  Blog Creature
//
//  Created by Daniel Weber on 8/8/12.
//
//

#import "LSColorPopUpButton.h"
#import "NSColor+Hex.h"
#import "RegexKitLite.h"

CGFloat const kArrowWidth = 10.f;
CGFloat const kSwatchWidth = 30.f;
CGFloat const kSwatchHeight = 6.0f;
CGFloat const kSwatchHorizontalPadding = 6.0f;
CGFloat const kHorizontalPadding = 7.0;
CGFloat const kBottomPadding = 7.0;
CGFloat const kTopPadding = 6.0;
NSInteger const kCurrentColorTag = 9999;

@interface LSPopUpButtonCell : NSPopUpButtonCell
@end

@implementation LSPopUpButtonCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self indexOfSelectedItem] >= 0 && [self indexOfSelectedItem] < [self numberOfItems]) {
        NSImage *swatch = [[self selectedItem] image];
        if (!swatch)
            return;
        NSBitmapImageRep *rawImage = [NSBitmapImageRep imageRepWithData:[swatch TIFFRepresentation]];
        NSColor *color = [rawImage colorAtX:1 y:1];

        NSRect swatchRect = NSMakeRect(kHorizontalPadding, kTopPadding, NSWidth(cellFrame) - kArrowWidth - 2 * kHorizontalPadding, NSHeight(cellFrame) - kBottomPadding - kTopPadding);
        [[NSColor colorWithCalibratedWhite:205/255.f alpha:1.0] set];
        NSRectFill(swatchRect);
        [color set];
        NSRectFill(NSInsetRect(swatchRect, 1, 1));
    }
}

@end

@implementation LSColorPopUpButton

- (void)awakeFromNib {
    NSPopUpButtonCell *oldCell = [self cell];
    LSPopUpButtonCell *newCell = [[[LSPopUpButtonCell alloc] init] autorelease];
    [newCell setControlSize:[oldCell controlSize]];
    [newCell setBezelStyle:[oldCell bezelStyle]];
    [newCell setTarget:[oldCell target]];
    [newCell setAction:[oldCell action]];
    [self setCell:newCell];

    hexToNameDict = [[NSMutableDictionary dictionary] retain];
    nameToRGBDict = [[NSMutableDictionary dictionary] retain];
    nameToHexDict = [[NSMutableDictionary dictionary] retain];
    
    [self setup];
}

- (void)dealloc {
    [hexToNameDict release];
    [nameToHexDict release];
    [nameToRGBDict release];
    self.rgbString = nil;
    self.hexString = nil;
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSRect colorRect = NSMakeRect(0, 0, NSWidth([self bounds]) - kArrowWidth - kHorizontalPadding, NSHeight([self bounds]));
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (NSPointInRect(point, colorRect)) {
        mouseDownInColorSection = YES;
    } else {
        mouseDownInColorSection = NO;
        [super mouseDown:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (mouseDownInColorSection) {
        NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
        [colorPanel setTarget:self];
        [colorPanel setAction:@selector(colorClicked:)];
        [colorPanel setColor:[NSColor colorFromHexRGB:self.hexString]];
        [colorPanel orderFront:nil];
    }
}

- (void)colorClicked:(id)sender {
    NSColor *color = [NSColorPanel sharedColorPanel].color;
    self.hexString = [color hexString];
    self.rgbString = [NSString stringWithFormat:@"rgb(%g, %g, %g)", color.redComponent*255.0, color.greenComponent*255.0, color.blueComponent*255.0];
    [self selectRGBColorString:self.rgbString];
    [self.target performSelector:self.action];
}

- (void)clearColor {
    for (NSMenuItem *item in [self itemArray]) {
        if ([item tag] == 1 || [item tag] == 2)
            [[self menu] removeItem:item];
    }
    self.rgbString = nil;
    self.hexString = nil;
    [self selectItemAtIndex:-1];
}

- (NSImage *)imageForColor:(NSColor *)color {
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(kSwatchWidth, kSwatchHeight+2*kSwatchHorizontalPadding)] autorelease];
    NSRect imageRect = NSMakeRect(0, kSwatchHeight, kSwatchWidth, kSwatchHeight);
    [image lockFocus];
    [[NSColor blackColor] set];
    NSRectFill(imageRect);
    [color set];
    NSRectFill(NSInsetRect(imageRect, 1.0, 1.0));
    [image unlockFocus];
    return image;
}

- (NSArray *)componentsOfRGBString:(NSString *)rgbString {
    CGFloat red, green, blue, alpha;
    NSString *regex = @"rgba?\\s*?\\(\\s*(.*?)\\s*,\\s*(.*?)\\s*,\\s*(.*?)\\s*(?:,\\s*(.*?)\\s*)?\\)";
    NSArray *matches = [[rgbString arrayOfCaptureComponentsMatchedByRegex:regex] objectAtIndex:0];
    alpha = [[matches objectAtIndex:4] length] == 0 ? 1.0 : [[matches objectAtIndex:4] floatValue];
    red = [[matches objectAtIndex:1] floatValue];
    green = [[matches objectAtIndex:2] floatValue];
    blue = [[matches objectAtIndex:3] floatValue];
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue], [NSNumber numberWithFloat:alpha], nil];
}

- (void)selectRGBColorString:(NSString *)string {
    NSMenuItem *colorItem = [[self menu] itemWithTag:1];
    if (!colorItem) {
        [[self menu] insertItemWithTitle:@"" action:nil keyEquivalent:@"" atIndex:0];
        [[self itemAtIndex:0] setTag:1];
        [[self menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
        [[self itemAtIndex:1] setTag:2];
        colorItem = [[self menu] itemWithTag:1];
    }
    NSArray *colorComponents = [self componentsOfRGBString:string];
    NSInteger red = [[colorComponents objectAtIndex:0] integerValue];
    NSInteger green = [[colorComponents objectAtIndex:1] integerValue];
    NSInteger blue = [[colorComponents objectAtIndex:2] integerValue];
    CGFloat alpha = [[colorComponents objectAtIndex:3] floatValue];

    // Create title
    NSString *colorTitle;
    if (alpha == 1.0) {
        // Convert the numbers to hex strings
        NSString *redHexValue = [NSString stringWithFormat:@"%02lX", (long)red];
        NSString *greenHexValue = [NSString stringWithFormat:@"%02lX", (long)green];
        NSString *blueHexValue = [NSString stringWithFormat:@"%02lX", (long)blue];
        colorTitle = [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
        self.hexString = [colorTitle substringFromIndex:1];
        //NSLog(@"%@", hexToNameDict);
        if ([hexToNameDict objectForKey:colorTitle]) {
            colorTitle = [NSString stringWithFormat:@"%@ (%@)", [hexToNameDict objectForKey:colorTitle], colorTitle];
        }
    } else {
        colorTitle = [NSString stringWithFormat:@"rgba(%f, %f, %f, %f)", red/255.0, green/255.0, blue/255.0, alpha];
    }
    [colorItem setTitle:colorTitle];
    
    self.rgbString = [NSString stringWithFormat:@"rgb(%li, %li, %li)", red, green, blue];

    // Create swatch
    NSColor *color = [NSColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
    NSImage *colorImage = [self imageForColor:color];
    [colorItem setImage:colorImage];

    [self selectItem:colorItem];
}

- (void)colorSelected:(id)sender {
    self.hexString = [nameToHexDict objectForKey:[sender title]];
    self.rgbString = [nameToRGBDict objectForKey:[sender title]];
    [self selectRGBColorString:self.rgbString];
    [self.target performSelector:self.action withObject:self];
}

- (void)setup {
    [self removeAllItems];

    //[[self menu] setFont:[NSFont systemFontOfSize:10.0]];
    //[[self menu] setShowsStateColumn:NO];

    [[self menu] addItemWithTitle:@"" action:nil keyEquivalent:@""];
    [[self lastItem] setTag:1];
    [[self menu] addItem:[NSMenuItem separatorItem]];
    [[self lastItem] setTag:2];
    //[[self menu] addItemWithTitle:@"Recent Colors" action:nil keyEquivalent:@""];
    //[[self lastItem] setTarget:nil];
    //[[self menu] addItem:[NSMenuItem separatorItem]];
    //[[self menu] addItemWithTitle:@"Named Colors" action:nil keyEquivalent:@""];
    //[[self lastItem] setTarget:nil];
    //self.menu.font = [NSFont fontWithName:@"Helvetica" size:13.0];
    
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"colors" ofType:@"txt"];
	NSString *colors = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [colors componentsSeparatedByString:@"\n"];
    NSInteger colorIndex = 0;
    NSInteger targetColorIndex = 0;
	for (NSString *line in lines) {
		if ([[line substringToIndex:1] isEqualToString:@"#"]) {
            NSArray *titleTokens = [[line substringFromIndex:1] componentsSeparatedByString:@";"];
            NSMenuItem *colorGroupItem = [[[NSMenuItem alloc] initWithTitle:[titleTokens objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
            colorIndex = 0;
            targetColorIndex = [[titleTokens objectAtIndex:1] integerValue];
            NSMenu *colorGroupMenu = [[[NSMenu alloc] init] autorelease];
            [colorGroupItem setSubmenu:colorGroupMenu];
            [[self menu] addItem:colorGroupItem];

            /*NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [style setAlignment:NSCenterTextAlignment];

            NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
            //[attrs setObject:style forKey:NSParagraphStyleAttributeName];
            [attrs setObject:[NSFont boldSystemFontOfSize:10.0] forKey:NSFontAttributeName];

            NSString *title = [[line substringFromIndex:1] uppercaseString];
            [self addItemWithTitle:@""];
            [[self lastItem] setAttributedTitle:[[[NSAttributedString alloc] initWithString:title attributes:attrs] autorelease]];
            //[self addItemWithTitle:[line substringFromIndex:1]];
            [[self lastItem] setTarget:nil];*/
		} else {
            NSMenuItem *lastItem = [[[self menu] itemArray] lastObject];
            NSArray *colorItemTokens = [line componentsSeparatedByString:@";"];
            NSString *hexString = [[[colorItemTokens objectAtIndex:1] componentsSeparatedByString:@","] componentsJoinedByString:@""];
            NSString *rgbString = [NSString stringWithFormat:@"rgb(%@)", [colorItemTokens objectAtIndex:2]];
            NSColor *color = [NSColor colorFromHexRGB:hexString];
            NSImage *colorImage = [self imageForColor:color];
            
            [hexToNameDict setObject:[colorItemTokens objectAtIndex:0] forKey:[NSString stringWithFormat:@"#%@", hexString]];
            [nameToRGBDict setObject:rgbString forKey:[colorItemTokens objectAtIndex:0]];
            [nameToHexDict setObject:hexString forKey:[colorItemTokens objectAtIndex:0]];

            if (colorIndex == targetColorIndex) {
                //[lastItem setImage:colorImage];
            }
            colorIndex++;

            NSMenu *lastMenu = [lastItem submenu];
            NSMenuItem *colorMenuItem = [[[NSMenuItem alloc] initWithTitle:[colorItemTokens objectAtIndex:0] action:@selector(colorSelected:) keyEquivalent:@""] autorelease];
            [colorMenuItem setTarget:self];
            [colorMenuItem setImage:colorImage];

            [lastMenu addItem:colorMenuItem];
		}
	}
}

@end
