//
//  MediaController.h
//  Blog Creature
//
//  Created by Daniel Weber on 11/11/12.
//
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

typedef enum {
    MediaPanelInsertMode,
    MediaPanelChooseMode
} MediaPanelMode;

@class DataManager, PostsController, ImageWithPathView, XMLRPCManager, AccountsController, EditController;

@interface MediaController : NSObject <NSURLDownloadDelegate> {
    IBOutlet XMLRPCManager*         xmlrpcManager;
    IBOutlet AccountsController*    accountsController;
    IBOutlet DataManager*           dataManager;
    IBOutlet PostsController*       postsController;
    IBOutlet EditController*        editController;
    MediaPanelMode mode;
    NSInteger fileDownloadCount;
}

@property (nonatomic, assign) IBOutlet NSWindow *mainWindow;
@property (nonatomic, assign) IBOutlet NSPanel *mediaPanel;
@property (nonatomic, assign) IBOutlet IKImageBrowserView *imageBrowserView;
@property (nonatomic, assign) IBOutlet NSSlider *imageBrowserSizeSlider;
@property (nonatomic, assign) IBOutlet ImageWithPathView *uploadImageView;
@property (nonatomic, assign) IBOutlet NSTextField *uploadFileNameField;
@property (nonatomic, assign) IBOutlet NSTextField *uploadFileSizeField;
@property (nonatomic, assign) IBOutlet NSPopUpButton *uploadDocumentTypePopUpButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *uploadImageSizePopUpButton;
@property (nonatomic, assign) IBOutlet NSTextField *uploadImageWidthField;
@property (nonatomic, assign) IBOutlet NSTextField *uploadImageHeightField;
@property (nonatomic, assign) IBOutlet NSSlider *uploadImageQualitySlider;
@property (nonatomic, assign) IBOutlet NSButton *uploadImageButton;
@property (nonatomic, assign) IBOutlet NSWindow *downloadProgressWindow;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *downloadProgressIndicator;
@property (nonatomic, retain) NSMutableArray *downloadQueue;


@property (nonatomic, assign) IBOutlet NSButton *okButton;

- (void)setMode:(MediaPanelMode)aMode;
- (void)showMediaPanelForWindow:(NSWindow *)window;
- (void)handleUploadFileResponseWithData:(id)data;
- (void)handleGetMediaLibraryResponseWithData:(id)data;
- (void)loadMediaFromCache;
- (IBAction)cancelDownload:(id)sender;
- (IBAction)reloadMediaLibrary:(id)sender;
- (NSArray *)imageExtensions;
- (NSString *)mimeTypeForFile:(NSString *)file;
- (NSBitmapImageFileType)fileTypeForFile:(NSString *)file;

@end
