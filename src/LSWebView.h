//
//  MyWebView.h
//  Sitemaker
//
//  Created by Dan Weber on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>


@class OverlayView;
@class ImageOverlayView;
@class DataManager;
@class MediaController;
@class LSColorPopUpButton;

@interface LSWebView : WebView <NSPopoverDelegate> {
	ImageOverlayView *imageOverlayView;
}

- (void)hideOverlayView;
- (NSRect)frameForNode:(DOMNode *)node;
- (NSRect)contentFrameForNode:(DOMNode *)node;
- (IBAction)borderSelected:(id)sender;

@property (nonatomic, assign) IBOutlet MediaController *mediaController;
@property (nonatomic, assign) IBOutlet DataManager *dataManager;
@property (nonatomic, retain) DOMNode *imageNode;
@property (nonatomic, retain) NSTrackingArea *trackingArea;

@property (nonatomic, assign) IBOutlet NSPopover *imagePopover;
@property (nonatomic, assign) IBOutlet NSTextField *imageWidthField;
@property (nonatomic, assign) IBOutlet NSTextField *imageHeightField;
@property (nonatomic, assign) IBOutlet NSTextField *imageMarginTopField;
@property (nonatomic, assign) IBOutlet NSTextField *imageMarginBottomField;
@property (nonatomic, assign) IBOutlet NSTextField *imageMarginRightField;
@property (nonatomic, assign) IBOutlet NSTextField *imageMarginLeftField;

@property (nonatomic, assign) IBOutlet NSSegmentedControl *imageBorderSegmentedControl;
@property (nonatomic, assign) IBOutlet NSPopUpButton *imageBorderStylePopUpButton;
@property (nonatomic, assign) IBOutlet LSColorPopUpButton *imageBorderColorPopUpButton;
@property (nonatomic, assign) IBOutlet NSTextField *imageBorderWidthField;

@end
