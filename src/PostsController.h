//
//  PostsViewController.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/16/12.
//
//

#import <Foundation/Foundation.h>
#import "TLAnimatingOutlineView.h"


@class XMLRPCManager, AccountsController, DataManager, EditController, LSFeaturedImageView, MediaController, PostsOutlineViewDelegate, LSDocument;

@interface PostsController : NSObject <TLAnimatingOutlineViewDelegate, NSTextFieldDelegate> {
    IBOutlet XMLRPCManager*         xmlrpcManager;
    IBOutlet AccountsController*    accountsController;
    IBOutlet MediaController*       mediaController;
    IBOutlet DataManager*           dataManager;
    IBOutlet EditController*        editController;
    
    IBOutlet NSSplitView*           splitView;
    IBOutlet NSScrollView*          detailScrollView;
    IBOutlet NSView*                detailPostInfoView;
    IBOutlet NSView*                detailCategoriesAndTagsView;
    IBOutlet NSView*                detailCustomFieldsView;
    IBOutlet NSView*                detailExcerptView;
    IBOutlet NSView*                detailPublishingOptionsView;
    IBOutlet NSView*                detailFeaturedImageView;
    IBOutlet NSView*                detailDiscussionView;

    IBOutlet NSWindow*              customFieldWindow;
    IBOutlet NSWindow*              categoryWindow;
}

@property (nonatomic, assign) IBOutlet PostsOutlineViewDelegate *postsOutlineViewDelegate;
@property (nonatomic, assign) IBOutlet NSOutlineView *postsOutlineView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *categoriesPopUpButton;
@property (nonatomic, assign) IBOutlet NSTokenField *tagsTokenField;
@property (nonatomic, assign) IBOutlet NSTableView *customFieldsTableView;
@property (nonatomic, assign) IBOutlet NSTextField *slugField;
@property (nonatomic, assign) IBOutlet NSTextField *excerptField;
@property (nonatomic, assign) IBOutlet NSTextField *titleField;
@property (nonatomic, assign) IBOutlet NSPopUpButton *postStatusPopUpButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *authorPopUpButton;
@property (nonatomic, assign) IBOutlet NSTextField *dateField;
@property (nonatomic, assign) IBOutlet NSTextField *passwordField;
@property (nonatomic, assign) IBOutlet NSButton *isStickyButton;
@property (nonatomic, assign) IBOutlet LSFeaturedImageView *featuredImageView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *formatPopUpButton;

@property (nonatomic, assign) IBOutlet NSTextField *customFieldKeyField;
@property (nonatomic, assign) IBOutlet NSTextField *customFieldValueField;
@property (nonatomic, assign) IBOutlet NSButton *customFieldAddButton;
@property (nonatomic, assign) IBOutlet NSButton *customFieldRemoveButton;
@property (nonatomic, assign) IBOutlet NSButton *featuredImageAddButton;
@property (nonatomic, assign) IBOutlet NSButton *featuredImageRemoveButton;
@property (nonatomic, assign) IBOutlet NSTextField *categoryNameField;

@property (nonatomic, assign) IBOutlet NSMatrix *discussionCommentsMatrix;
@property (nonatomic, assign) IBOutlet NSMatrix *discussionPingsMatrix;

@property (nonatomic, assign) IBOutlet NSButton *deletePostButton;
@property (nonatomic, assign) IBOutlet NSButton *createPostButton;

@property (nonatomic, readonly) LSDocument *selectedDocument;
@property (nonatomic, readonly) NSString *selectedDocumentID;
@property (nonatomic, readonly) NSString *selectedDocumentTitle;
@property (nonatomic, readonly) BOOL isDocumentSelected;

- (void)start;
- (void)stop;
- (void)setEnabled:(BOOL)isEnabled;
- (void)setPostInformationEditable:(BOOL)flag;
- (void)resetPostInformation;
- (IBAction)commitPost:(id)sender;
- (IBAction)togglePostInfoSidebar:(id)sender;
- (void)reloadSelectedPostAndContent:(BOOL)shouldReloadContent;
- (LSDocument *)createDocument;
- (IBAction)deletePost:(id)sender;
- (IBAction)newPost:(id)sender;
- (void)selectPostWithID:(NSString *)postID;


@end
