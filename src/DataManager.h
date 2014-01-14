//
//  DataManager.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/8/12.
//
//

#import <Foundation/Foundation.h>


#define IN_TRIAL_MODE NO

@class AccountsController, PostsController, IKBBrowserItem, LSDocument, EditController;

@interface DataManager : NSObject {
    IBOutlet AccountsController*    accountsController;
    IBOutlet PostsController*       postsController;
    IBOutlet EditController*        editController;
}

- (void)start;
- (void)stop;

- (NSString *)blogHTMLPath;
- (NSString *)blogHTMLString;

- (NSString *)blogCSSPath;
- (NSString *)cssString;

- (void)removeAllCustomFields;
- (void)removeAllTags;
- (void)removeAllCategories;
- (void)removeAllAuthors;
- (void)removeAllMedia;

- (void)addCustomField:(NSDictionary *)customField;
- (void)addTag:(NSString *)tag;
- (void)addCategory:(NSString *)category;
- (void)addAuthor:(NSString *)author withID:(NSInteger)identifier;
- (void)addMediaItem:(IKBBrowserItem *)item;
- (void)loadPosts:(NSArray *)posts;
- (void)loadDrafts;
- (IBAction)saveDraft:(id)sender;
- (void)deleteSelectedDraft;
- (NSString *)createNewDraft;
- (NSString *)appSupportFolder;
- (NSString *)localMediaFolder;

- (void)cacheObject:(id)object toFolder:(NSString *)folder;
- (void)loadAuthorsFromCache;
- (void)loadCategoriesFromCache;

- (NSString *)tmpFile;

@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) NSMutableArray *tags;
@property (nonatomic, retain) NSMutableArray *customFields;
@property (nonatomic, retain) NSMutableArray *deletedCustomFields;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSMutableArray *authors;
@property (nonatomic, retain) NSMutableArray *media;
@property (nonatomic, retain) NSMutableArray *mediaData;
@property (nonatomic, retain) NSMutableArray *drafts;
@property (nonatomic, retain) NSString *source;

//@property (nonatomic, readonly) NSString *postsCacheFolderPath;
//@property (nonatomic, readonly) NSString *blogDraftsFolder;
@property (nonatomic, copy) NSString *lastDraftFileName;
@property (nonatomic, retain) LSDocument *lastSelectedDocument;

@end