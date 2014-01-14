#import <Cocoa/Cocoa.h>


@class AccountsController, XMLRPCManager, DataManager, PostsController, EditController, INAppStoreWindow;

@interface AppDelegate : NSObject <NSWindowDelegate, NSApplicationDelegate> {
    IBOutlet AccountsController*    accountsController;
    IBOutlet XMLRPCManager*         xmlrpcManager;
    IBOutlet DataManager*           dataManager;
    IBOutlet PostsController*       postsController;
    IBOutlet EditController*        editController;

    IBOutlet INAppStoreWindow*      mainWindow;
    IBOutlet NSView*                mainView;
    IBOutlet NSView*                mainAccountView;
    IBOutlet NSView*                mainPostsView;
    IBOutlet NSView*                mainEditView;
    IBOutlet NSProgressIndicator*   toolbarProgressIndicator;
    IBOutlet NSTextField*           toolbarTitleField;
    IBOutlet NSButton*              toolbarGoToPostsButton;
    IBOutlet NSView*                toolbarButtonView;

    NSView*                         currentMainView;
}

@property (nonatomic, assign) IBOutlet NSButton *goToAccountsButton;
@property (nonatomic, assign) IBOutlet NSButton *goToPostsButton;
@property (nonatomic, assign) IBOutlet NSButton *goToEditorButton;
@property (nonatomic, assign) IBOutlet NSButton *actionButton;
@property (nonatomic, assign) IBOutlet NSMenuItem *goToAccountsMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *goToPostsMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *goToEditorMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *reloadPostsMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *reloadImagesMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *togglePostDetailsMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *showWYSIWYGMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *showHTMLMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *saveDraftMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *commitMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *showCSSEditorMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *togglePostPreviewMenuItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *loadPostPreviewMenuItem;

@end