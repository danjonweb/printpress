//
//  BrowseVersionsTableViewDelegate.h
//  Blog Creature
//
//  Created by Daniel Weber on 11/18/12.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class DataManager, EditController, PostsController;

@interface DraftsTableViewDelegate : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet DataManager *dataManager;
    IBOutlet EditController *editController;
    IBOutlet PostsController *postsController;
}

@property (nonatomic, retain) NSMutableArray *drafts;
@property (nonatomic, copy) NSString *draftsDirectory;
@property (nonatomic, assign) IBOutlet NSTextField *draftContentField;
@property (nonatomic, assign) IBOutlet WebView *draftContentWebView;
@property (nonatomic, assign) IBOutlet NSTableView *draftsTableView;
@property (nonatomic, assign) IBOutlet NSButton *deleteDraftsButton;
@property (nonatomic, assign) IBOutlet NSButton *openDraftButton;

//- (void)loadDraftsInPath:(NSString *)path;
//- (void)reset;
//- (NSString *)draftContent;

@end
