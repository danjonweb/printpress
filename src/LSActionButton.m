//
//  LSActionButton.m
//  Printpress
//
//  Created by Daniel Weber on 12/13/12.
//
//

#import "LSActionButton.h"
#import "NSImage+Tint.h"
#import "NSColor+Hex.h"

@implementation LSActionButton

- (void)mouseDown:(NSEvent *)theEvent {
    if (!self.isEnabled)
        return;
    NSPoint wp = {NSMinX([self bounds]), NSMaxY([self bounds])};
    wp = [self convertPoint:wp toView:nil];
    NSEvent *fakeEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:wp modifierFlags:0 timestamp:[theEvent timestamp] windowNumber:[theEvent windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:[theEvent clickCount] pressure:[theEvent pressure]];
    
    
    NSColor *toolbarIconColor = [NSColor darkGrayColor];
    NSColor *toolbarIconSelectedColor = [NSColor colorFromHexRGB:@"1D77EF"];
    
    self.image = [[NSImage imageNamed:@"764-arrow-down"] imageWithTint:toolbarIconSelectedColor];

    //[self setImage:[NSImage imageNamed:@"gear3-pressed.png"]];
    [NSMenu popUpContextMenu:self.menu withEvent:fakeEvent forView:self];
    //[self setImage:[NSImage imageNamed:@"gear3.png"]];
    
    self.image = [[NSImage imageNamed:@"764-arrow-down"] imageWithTint:toolbarIconColor];
}

@end
