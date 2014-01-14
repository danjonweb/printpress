#import "EditSplitViewDelegate.h"


@implementation EditSplitViewDelegate

# pragma mark -

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSView *top = [[splitView subviews] objectAtIndex:0];
    NSView *bottom = [[splitView subviews] objectAtIndex:1];
    float dividerThickness = [splitView dividerThickness];
    NSRect newFrame = [splitView frame];
    NSRect topFrame = [top frame];
    NSRect bottomFrame = [bottom frame];
    topFrame.size.height = newFrame.size.height - bottomFrame.size.height - dividerThickness;
    [top setFrame:topFrame];
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
        return proposedMaximumPosition - 100;
    }
    return proposedMaximumPosition;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

@end
