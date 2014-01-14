//
//  EditController.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/16/12.
//
//

#import <Foundation/Foundation.h>
#import <ACEView/ACEView.h>


typedef enum {
    EditorWYSIWYGMode,
    EditorMarkdownMode,
    EditorHTMLMode
} EditorMode;

@class WebView, LSColorPopUpButton, DataManager, PostsController, AccountsController, DraftsTableViewDelegate, MediaController, XMLRPCManager, INAppStoreWindow;

@interface EditController : NSObject <NSTextViewDelegate, NSTextFieldDelegate, NSPopoverDelegate, ACEViewDelegate> {
    IBOutlet DataManager*               dataManager;
    IBOutlet PostsController*           postsController;
    IBOutlet AccountsController*        accountsController;
    IBOutlet XMLRPCManager*             xmlrpcManager;
    IBOutlet NSTextView*                htmlTextView;
    IBOutlet DraftsTableViewDelegate*   draftsTableViewDelegate;
    IBOutlet MediaController*           mediaController;
}

- (void)start;
- (void)stop;
- (void)activate;
- (IBAction)showEditor:(id)sender;
- (IBAction)showCSSEditor:(id)sender;
- (IBAction)showPreview:(id)sender;
- (void)setWebViewEnabled:(BOOL)isEnabled;
- (IBAction)loadBlogTheme:(id)sender;
- (void)refreshPostPreview;
- (void)updatePreview;
- (NSString *)replaceMoreTags:(NSString *)html;
- (NSString *)restoreMoreTags:(NSString *)html;
- (IBAction)tidyAction:(id)sender;
- (void)focusHTMLEditor;

@property (nonatomic, assign) IBOutlet NSWindow *mainWindow;
@property (nonatomic, copy) NSString *html;
@property (nonatomic, assign) EditorMode editorMode;
@property (nonatomic, assign) ACEMode editor2Mode;
@property (nonatomic, assign) IBOutlet ACEView *aceEditor;
@property (nonatomic, assign) IBOutlet ACEView *aceEditor2;
@property (nonatomic, retain) NSMutableArray *failedResources;

@property (nonatomic, assign) IBOutlet NSMenuItem *showWYSIWYGMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *showHTMLMenuItem;
@property (nonatomic, assign) IBOutlet NSTabView *editorTabView;
@property (nonatomic, assign) IBOutlet WebView *webView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *fontPopUpButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *styleSegmentedControl;
@property (nonatomic, assign) IBOutlet LSColorPopUpButton *colorPopUpButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *clearSegmentedControl;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *alignmentSegmentedControl;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *floatSegmentedControl;
@property (nonatomic, assign) IBOutlet NSPopUpButton *formatPopUpButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *listPopUpButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *insertPopUpButton;

@property (nonatomic, assign) IBOutlet WebView *previewWebView;
@property (nonatomic, assign) IBOutlet INAppStoreWindow *previewWindow;
@property (nonatomic) BOOL isThemeFirstLoad;

@property (nonatomic, assign) IBOutlet NSWindow *aceEditor2Window;

@property (nonatomic, copy) NSString *tmpFile;
@property (nonatomic) BOOL ignoreHTMLEditorStringChange;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *tidySegmentedControl;
@property (nonatomic, assign) IBOutlet NSTextField *tidyOptionsField;
@property (nonatomic, assign) IBOutlet NSPopover *tidyPopover;
@property (nonatomic, assign) IBOutlet NSTextField *tidyLinkField;
@property (nonatomic, assign) IBOutlet NSPopUpButton *htmlEditorThemePopUpButton;


@end
