//
//  DataManager.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/8/12.
//
//

#import "DataManager.h"
#import "AccountsController.h"
#import "IKBBrowserItem.h"
#import "LSDocument.h"
#import "PostsController.h"
#import "EditController.h"

@implementation DataManager

- (void)start {
    self.posts = [NSMutableArray array];
    self.categories = [NSMutableArray array];
    self.tags = [NSMutableArray array];
    self.customFields = [NSMutableArray array];
    self.deletedCustomFields = [NSMutableArray array];
    self.authors = [NSMutableArray array];
    self.media = [NSMutableArray array];
    self.mediaData = [NSMutableArray array];
    self.drafts = [NSMutableArray array];

}

- (void)stop {
    self.posts = nil;
    self.categories = nil;
    self.tags = nil;
    self.customFields = nil;
    self.deletedCustomFields = nil;
    self.authors = nil;
    self.media = nil;
    self.mediaData = nil;
    self.drafts = nil;
    self.lastSelectedDocument = nil;
    self.lastDraftFileName = nil;
}

#pragma mark -
#pragma mark Posts

- (void)loadPosts:(NSArray *)posts {
    [self.posts removeAllObjects];
    for (NSDictionary *postDict in posts) {
        LSDocument *postDoc = [LSDocument documentWithDictionary:postDict];
        postDoc.docType = DocumentPostType;
        [self.posts addObject:postDoc];
    }
}

#pragma mark -
#pragma mark HTML

- (NSString *)blogHTMLPath {
    NSString *path = [self appSupportFolder];
    path = [path stringByAppendingPathComponent:@"html"];

    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {} else
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];

    path = [path stringByAppendingPathComponent:accountsController.blogUUID];
    path = [path stringByAppendingPathExtension:@"html"];
    return path;
}

- (NSString *)blogHTMLString {
    NSString *blogHTMLPath = [self blogHTMLPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *htmlString = @"";
    if ([fm fileExistsAtPath:blogHTMLPath]) {
        htmlString = [NSString stringWithContentsOfFile:blogHTMLPath encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSString *defaultHTMLPath = [[NSBundle mainBundle] pathForResource:@"preview" ofType:@"html"];
        htmlString = [NSString stringWithContentsOfFile:defaultHTMLPath encoding:NSUTF8StringEncoding error:nil];
    }
    return htmlString;
}

#pragma mark -
#pragma mark CSS

- (NSString *)blogCSSPath {
    NSString *path = [self appSupportFolder];
    path = [path stringByAppendingPathComponent:@"style"];
    path = [path stringByAppendingPathComponent:accountsController.blogUUID];
    path = [path stringByAppendingPathExtension:@"css"];
    return path;
}

- (NSString *)cssString {
    NSString *blogCSSPath = [self blogCSSPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *cssString = @"";
    if ([fm fileExistsAtPath:blogCSSPath]) {
        cssString = [NSString stringWithContentsOfFile:blogCSSPath encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSString *defaultCSSPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"css"];
        cssString = [NSString stringWithContentsOfFile:defaultCSSPath encoding:NSUTF8StringEncoding error:nil];
    }
    return cssString;
}

#pragma mark -
#pragma mark Drafts

- (NSString *)appSupportFolder {
    NSError *error;
    NSString *appSupportFolder = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error] path];
    //NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    //cachePath = [cachePath stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
    appSupportFolder = [appSupportFolder stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
    return appSupportFolder;
}

- (NSString *)postsCacheFolder {
    NSString *cachePath = [[self appSupportFolder] stringByAppendingPathComponent:@"posts"];
    cachePath = [cachePath stringByAppendingPathComponent:accountsController.blogUUID];

    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachePath isDirectory:&isDir] && isDir) {} else
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:NULL];

    return cachePath;
}

- (NSString *)localMediaFolder {
    NSString *cachePath = [[self appSupportFolder] stringByAppendingPathComponent:@"media-local"];
    
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachePath isDirectory:&isDir] && isDir) {} else
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    return cachePath;
}

- (void)cacheObject:(id )object toFolder:(NSString *)folder {
    NSString *cachePath = [[self appSupportFolder] stringByAppendingPathComponent:folder];

    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachePath isDirectory:&isDir] && isDir) {} else
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:NULL];

    cachePath = [cachePath stringByAppendingPathComponent:accountsController.blogUUID];
    cachePath = [cachePath stringByAppendingPathExtension:@"plist"];

    [object writeToFile:cachePath atomically:NO];
}

- (void)loadAuthorsFromCache {
    NSString *cachePath = [[self appSupportFolder] stringByAppendingPathComponent:@"authors"];
    cachePath = [cachePath stringByAppendingPathComponent:accountsController.blogUUID];
    cachePath = [cachePath stringByAppendingPathExtension:@"plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachePath]) {
        self.authors = [[[NSMutableArray alloc] initWithContentsOfFile:cachePath] autorelease];
    }
}

- (void)loadCategoriesFromCache {
    NSString *cachePath = [[self appSupportFolder] stringByAppendingPathComponent:@"categories"];
    cachePath = [cachePath stringByAppendingPathComponent:accountsController.blogUUID];
    cachePath = [cachePath stringByAppendingPathExtension:@"plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachePath]) {
        self.categories = [[[NSMutableArray alloc] initWithContentsOfFile:cachePath] autorelease];
    }
}

- (NSString *)createNewDraft {
    NSString *draftID = @"-1";
    NSString *draftPath = [self postsCacheFolder];
    NSString *fileName = [NSString stringWithFormat:@"%@_%f.plist", draftID, [NSDate timeIntervalSinceReferenceDate]];
    draftPath = [draftPath stringByAppendingPathComponent:fileName];
    LSDocument *postDoc = [LSDocument document];
    postDoc.docType = DocumentDraftType;
    postDoc.fileName = fileName;
    postDoc.postID = [NSString stringWithFormat:@"%@", draftID];
    
    postDoc.postTitle = @"New Post";
    postDoc.postName = @"";
    postDoc.postExcerpt = @"";
    postDoc.postDateGMT = [NSDate date];
    postDoc.isSticky = @(0);
    postDoc.postPassword = @"";
    postDoc.postFormat = @"standard";
    postDoc.postStatus = @"publish";
    
    postDoc.postContent = @"";
    
    NSDictionary *postDict = postDoc.dictionary;
    [postDict writeToFile:draftPath atomically:NO];
    [self loadDrafts];
    return fileName;
}

- (IBAction)saveDraft:(id)sender {
    NSString *draftPath = [self postsCacheFolder];
    NSString *fileName = @"";
    if (postsController.selectedDocument.docType == DocumentPostType) {
        fileName = [NSString stringWithFormat:@"%@_%f.plist", postsController.selectedDocumentID, [NSDate timeIntervalSinceReferenceDate]];
    } else if (postsController.selectedDocument.docType == DocumentDraftType) {
        fileName = postsController.selectedDocument.fileName;
    }

    draftPath = [draftPath stringByAppendingPathComponent:fileName];
    LSDocument *postDoc = [postsController createDocument];
    
    DOMDocument *domDoc = [editController.webView mainFrameDocument];
    DOMNodeList *imgList = [domDoc getElementsByTagName:@"img"];
    for (int i = 0; i < [imgList length]; i++) {
        DOMElement *element = (DOMElement *)[imgList item:i];
        NSString *src = [element getAttribute:@"src"];
        for (IKBBrowserItem *item in self.media) {
            if ([item.URL.absoluteString.lastPathComponent isEqualToString:src.lastPathComponent]) {
                [element setAttribute:@"src" value:item.fileName];
                break;
            }
        }
    }
    postDoc.postContent = domDoc.body.innerHTML;
    
    postDoc.fileName = fileName;
    self.lastDraftFileName = fileName;
    NSDictionary *postDict = postDoc.dictionary;
    [postDict writeToFile:draftPath atomically:NO];
    
    [[NSApp mainWindow] setDocumentEdited:NO];

    [self loadDrafts];
}

- (void)deleteSelectedDraft {
    NSString *fileName = [[self postsCacheFolder] stringByAppendingPathComponent:postsController.selectedDocument.fileName];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
    [self loadDrafts];
}

- (void)loadDrafts {
    self.lastSelectedDocument = postsController.selectedDocument;
    
    [self.drafts removeAllObjects];
    NSString *draftsFolder = [self postsCacheFolder];
    NSError *error = nil;
    NSArray *filePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:draftsFolder error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
    }
    for (NSString *filePath in filePaths) {
        if ([[filePath lastPathComponent] hasPrefix:@"."] || [[filePath lastPathComponent] isEqualToString:@"Icon\r"])
            continue;
        NSString *path = [draftsFolder stringByAppendingPathComponent:filePath];
        NSDictionary *postDict = [NSDictionary dictionaryWithContentsOfFile:path];
        LSDocument *postDoc = [LSDocument documentWithDictionary:postDict];

        [self.drafts addObject:postDoc];
    }
    [postsController.postsOutlineView reloadItem:nil reloadChildren:YES];
    [postsController.postsOutlineView expandItem:nil expandChildren:YES];

    BOOL postSelected = NO;
    for (int i = 0; i < postsController.postsOutlineView.numberOfRows; i++) {
        id item = [postsController.postsOutlineView itemAtRow:i];

        if ([item isKindOfClass:[LSDocument class]]) {
            LSDocument *document = (LSDocument *)item;
            if (document.docType == DocumentPostType) {
                if (document == self.lastSelectedDocument) {
                    [postsController.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
                    postSelected = YES;
                }
            } else if (document.docType == DocumentDraftType) {
                if (self.lastDraftFileName && [self.lastDraftFileName isEqualToString:document.fileName]) {
                    [postsController.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
                    postSelected = YES;
                } else if ([document.fileName isEqualToString:self.lastSelectedDocument.fileName]) {
                    [postsController.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
                    postSelected = YES;
                }
            }
        }
    }
    
    self.lastDraftFileName = nil;

    if (postSelected) {
        if (self.lastSelectedDocument.docType == DocumentPostType)
            [editController activate];
    } else {
        [postsController.postsOutlineView deselectAll:nil];
    }
}

#pragma mark -
#pragma mark Add/Removing

- (void)addTag:(NSString *)tag {
    [self.tags addObject:tag];
}

- (void)addCategory:(NSString *)category {
    [self.categories addObject:category];
}

- (void)addAuthor:(NSString *)author withID:(NSInteger)identifier {
    [self.authors addObject:@{@"display_name" : author, @"user_id" : @(identifier)}];
}

- (void)addCustomField:(NSDictionary *)customField {
    [self.customFields addObject:customField];
}

- (void)addMediaItem:(IKBBrowserItem *)item {
    [self.media addObject:item];
    [self.media sortUsingComparator:(NSComparator)^(id obj1, id obj2){
        NSString *title1 = ((IKBBrowserItem *)obj1).title;
        NSString *title2 = ((IKBBrowserItem *)obj2).title;
        return [title1 caseInsensitiveCompare:title2];
    }];
}

- (void)removeAllCustomFields {
    [self.customFields removeAllObjects];
    [self.deletedCustomFields removeAllObjects];
}

- (void)removeAllTags {
    [self.tags removeAllObjects];
}

- (void)removeAllCategories {
    [self.categories removeAllObjects];
}

- (void)removeAllAuthors {
    [self.authors removeAllObjects];
}

- (void)removeAllMedia {
    [self.media removeAllObjects];
    [self.mediaData removeAllObjects];
}

#pragma mark -

- (NSString *)tmpFile {
    NSString *tempFileTemplate = [NSTemporaryDirectory()
                                  stringByAppendingPathComponent:@"temp-file-XXXXXX.txt"];
    
    const char *tempFileTemplateCString =
    [tempFileTemplate fileSystemRepresentation];
    
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemps(tempFileNameCString, 4);
    
    // no need to keep it open
    close(fileDescriptor);
    
    if (fileDescriptor == -1) {
        NSLog(@"Error while creating tmp file");
        return nil;
    }
    
    NSString *tempFileName = [[NSFileManager defaultManager]
                              stringWithFileSystemRepresentation:tempFileNameCString
                              length:strlen(tempFileNameCString)];
    
    free(tempFileNameCString);
    
    return tempFileName;
}

@end
