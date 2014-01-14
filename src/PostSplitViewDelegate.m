#import "PostSplitViewDelegate.h"


@implementation PostSplitViewDelegate

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSView *left = [[splitView subviews] objectAtIndex:0];
    NSView *right = [[splitView subviews] objectAtIndex:1];
    float dividerThickness = [splitView dividerThickness];
    NSRect newFrame = [splitView frame];
    NSRect leftFrame = [left frame];
    NSRect rightFrame = [right frame];
    leftFrame.size.width = newFrame.size.width - rightFrame.size.width - dividerThickness;
    [left setFrame:leftFrame];
    [splitView adjustSubviews];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return proposedMinimumPosition + 100;
    }
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return proposedMaximumPosition - 251;
    }
    return proposedMaximumPosition;
}

# pragma mark -

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		NSRect rect = [[[splitView subviews] objectAtIndex:1] convertRect:[dividerBar frame] toView:splitView];
		NSRect leftRect, rightRect;
		NSDivideRect(rect, &leftRect, &rightRect, 20.f, NSMinXEdge);
		return leftRect;
	}
	return NSZeroRect;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if (subview == [[splitView subviews] objectAtIndex:1]) {
        return YES;
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    if (dividerIndex == 0)
        return YES;
    return NO;
}

@end
