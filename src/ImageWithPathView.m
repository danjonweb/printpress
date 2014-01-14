//
//  ImageWithPathView.m
//  Blog Creature
//
//  Created by Daniel Weber on 7/25/12.
//
//

#import "ImageWithPathView.h"


NSString *UploadImageDidChangeNotification = @"UploadImageDidChangeNotification";

NSRect NSRectCenteredInNSRect(NSRect inner, NSRect outer) {
    return NSMakeRect((outer.size.width - inner.size.width) / 2.0, (outer.size.height - inner.size.height) / 2.0, inner.size.width, inner.size.height);
}

@implementation ImageWithPathView

@synthesize filePath;

- (void)setImage:(NSImage *)image
{
    [image setName:self.filePath];
    [super setImage:image];
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadImageDidChangeNotification object:image];
}

- (void)dealloc {
    [filePath release];
    [super dealloc];
}

- (CGFloat)imageScale {
    CGFloat sx = self.frame.size.width / self.image.size.width;
    CGFloat sy = self.frame.size.height / self.image.size.height;
    return sx <= sy ? sx : sy;
}

- (NSRect)imageRect {
    CGFloat imgScale = [self imageScale];
    NSSize imgSize = [self image].size;
    NSRect rect = NSMakeRect(0, 0, (NSInteger)(imgSize.width * imgScale), (NSInteger)(imgSize.height * imgScale));

    //NSLog(@"%@", NSStringFromRect(rect));
    return NSRectCenteredInNSRect(rect, self.frame);
}

- (BOOL)performDragOperation:(id )sender {
    BOOL dragSucceeded = [super performDragOperation:sender];
    if (dragSucceeded) {
        NSString *filenamesXML = [[sender draggingPasteboard] stringForType:NSFilenamesPboardType];
        if (filenamesXML) {
            NSArray *filenames = [NSPropertyListSerialization
                                  propertyListFromData:[filenamesXML dataUsingEncoding:NSUTF8StringEncoding]
                                  mutabilityOption:NSPropertyListImmutable
                                  format:nil
                                  errorDescription:nil];
            if ([filenames count] >= 1) {
                self.filePath = [filenames objectAtIndex:0];
            } else {
                self.filePath = nil;
            }
        }
    }
    return dragSucceeded;
}

- (void)drawRect:(NSRect)dirtyRect {
    if ([self image] == nil) {
        NSRect bounds = NSInsetRect([self bounds], 2.5f, 2.5f);
        NSColor *currentColor;
        if ([[self window] firstResponder] == self) {
            currentColor = [NSColor keyboardFocusIndicatorColor];
        } else {
            currentColor = [NSColor lightGrayColor];
        }
        [currentColor set];
        /*CGFloat pat[2] = {8.5, 5.5};
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:10.f yRadius:10.f];
        [path setLineDash:pat count:2.0 phase:0.f];
        [path setLineWidth:3.f];
        [path stroke];*/
        NSRectFill([self bounds]);

        NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSFont *font = [NSFont boldSystemFontOfSize:12.0];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName, font, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
        NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:@"Drag a file here" attributes:attrs] autorelease];
        [attrString drawInRect:NSMakeRect(0, NSMidY(bounds) - [attrString size].height / 2.f, NSWidth(bounds), [attrString size].height)];
    } else {
        NSRect imageRect = [self imageRect];
        imageRect = NSInsetRect(imageRect, 2.0, 2.0);
        if ([[self window] firstResponder] == self) {
            [[NSColor keyboardFocusIndicatorColor] set];
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            NSFrameRect(imageRect);
            [NSGraphicsContext restoreGraphicsState];
        }
        [[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

        
    }
}

@end