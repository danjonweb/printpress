//
//  PostsViewController.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/16/12.
//
//

#import "PostsController.h"
#import "XMLRPCManager.h"
#import "AccountsController.h"
#import "DataManager.h"
#import "IKBBrowserItem.h"
#import "LSFeaturedImageView.h"
#import "MediaController.h"
#import "EditController.h"
#import "PostsOutlineViewDelegate.h"
#import "LSDocument.h"
#import "NSString+HTML.h"


@implementation PostsController

- (void)start {
    // Setup Outline View.
	NSSize contentSize = [detailScrollView contentSize];
	TLAnimatingOutlineView *outlineView = [[[TLAnimatingOutlineView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, contentSize.width, contentSize.height)] autorelease];
	[outlineView setDelegate:self];
	[outlineView setAutoresizingMask:NSViewWidthSizable]; // should not be combined with NSviewHieghtSizable else we have incorrect scrollbar showing/hiding/sizing behaviour.
	[detailScrollView setDocumentView:outlineView];
	[outlineView addView:detailPostInfoView withImage:nil label:@"Post Info" expanded:YES];
    [outlineView addView:detailPublishingOptionsView withImage:nil label:@"Publishing Options" expanded:YES];
	[outlineView addView:detailCategoriesAndTagsView withImage:nil label:@"Categories and Tags" expanded:YES];
    [outlineView addView:detailFeaturedImageView withImage:nil label:@"Featured Image" expanded:YES];
    [outlineView addView:detailCustomFieldsView withImage:nil label:@"Custom Fields" expanded:YES];
	[outlineView addView:detailExcerptView withImage:nil label:@"Excerpt" expanded:YES];
    [outlineView addView:detailDiscussionView withImage:nil label:@"Discussion Options" expanded:YES];

    [self.postsOutlineView setTarget:self.postsOutlineViewDelegate];
    [self.postsOutlineView setDoubleAction:@selector(postDoubleClicked:)];
    
    NSDateFormatter *df = self.dateField.formatter;
    df.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];

    [self.postStatusPopUpButton selectItemAtIndex:-1];
    
    [self.postsOutlineViewDelegate start];
}

- (void)stop {
    [self.postsOutlineViewDelegate stop];
}

- (BOOL)isDocumentSelected {
    return [self.postsOutlineView selectedRow] >= 0;
}

- (void)setEnabled:(BOOL)isEnabled {
    [self.postsOutlineView setEnabled:isEnabled];
    [editController setWebViewEnabled:isEnabled];
    if (!isEnabled || (isEnabled && self.isDocumentSelected))
        [self setPostInformationEditable:isEnabled];
}

- (NSString *)selectedDocumentTitle {
    if (self.isDocumentSelected) {
        return self.selectedDocument.postTitle;
    }
    return @"Edit Post";
}

- (NSString *)selectedDocumentID {
    if (self.isDocumentSelected) {
        return self.selectedDocument.postID;
    }
    return nil;
}

- (LSDocument *)selectedDocument {
    if (self.isDocumentSelected) {
        return [self.postsOutlineView itemAtRow:self.postsOutlineView.selectedRow];
    }
    return nil;
}

- (void)reloadSelectedPostAndContent:(BOOL)shouldReloadContent {
    [self.postsOutlineViewDelegate reloadSelectedPostAndContent:shouldReloadContent];
}

- (void)selectPostWithID:(NSString *)postID {
    [self.postsOutlineViewDelegate selectPostWithID:postID];
}

- (CGFloat)rowSeparation {
    // For Collapsing Outline View
	return 0.f;
}

#pragma mark -
#pragma mark Enable/Disable

- (void)setPostInformationEditable:(BOOL)flag {
    [self.titleField setEnabled:flag];
    [self.slugField setEnabled:flag];
    [self.authorPopUpButton setEnabled:flag];
    [self.formatPopUpButton setEnabled:flag];
    [self.categoriesPopUpButton setEnabled:flag];
    [self.tagsTokenField setEnabled:flag];
    [self.customFieldsTableView setEnabled:flag];
    [self.customFieldAddButton setEnabled:flag];
    [self.customFieldRemoveButton setEnabled:flag];
    [self.excerptField setEnabled:flag];
    [self.postStatusPopUpButton setEnabled:flag];
    [self.dateField setEnabled:flag];
    [self.passwordField setEnabled:flag];
    [self.isStickyButton setEnabled:flag];
    [self.featuredImageView setEnabled:flag];
    [self.featuredImageAddButton setEnabled:flag];
    [self.featuredImageRemoveButton setEnabled:flag];
    [self.discussionCommentsMatrix setEnabled:flag];
    [self.discussionPingsMatrix setEnabled:flag];

    if (flag && [self.customFieldsTableView selectedRow] < 0) {
        [self.customFieldRemoveButton setEnabled:NO];
    }

    [self.deletePostButton setEnabled:flag];
}

- (void)resetPostInformation {
    [self.titleField setStringValue:@""];
    [self.slugField setStringValue:@""];
    [self.authorPopUpButton removeAllItems];
    [self.formatPopUpButton removeAllItems];
    [self.categoriesPopUpButton removeAllItems];
    [self.tagsTokenField setStringValue:@""];
    [self.excerptField setStringValue:@""];
    [self.postStatusPopUpButton selectItemAtIndex:-1];
    [self.passwordField setStringValue:@""];
    [self.isStickyButton setState:NSOffState];
    [self.featuredImageView setImageID:nil];
    [self.featuredImageView setImage:nil];
    [dataManager removeAllCustomFields];
    [self.customFieldsTableView reloadData];
    [self.dateField setStringValue:@""];
    [self.discussionCommentsMatrix deselectAllCells];
    [self.discussionPingsMatrix deselectAllCells];
}

#pragma mark -
#pragma mark Commit

- (LSDocument *)createDocument {
    LSDocument *postDoc = [LSDocument document];
    postDoc.docType = DocumentDraftType;
    postDoc.postID = self.selectedDocumentID;

    // Post Status
    if ([self.postStatusPopUpButton indexOfSelectedItem] == 0)
        postDoc.postStatus = @"publish";
    if ([self.postStatusPopUpButton indexOfSelectedItem] == 1)
        postDoc.postStatus = @"draft";
    if ([self.postStatusPopUpButton indexOfSelectedItem] == 2)
        postDoc.postStatus = @"pending";
    if ([self.postStatusPopUpButton indexOfSelectedItem] == 3)
        postDoc.postStatus = @"private";

    postDoc.postTitle = self.titleField.stringValue;
    postDoc.postAuthor = [NSString stringWithFormat:@"%li", [self.authorPopUpButton selectedTag]];
    postDoc.postFormat = self.formatPopUpButton.titleOfSelectedItem;
    postDoc.postExcerpt = self.excerptField.stringValue;
    /*
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeZone:tz];
    NSDate *date = [dateFormatter dateFromString:self.dateField.stringValue];
    
    postDoc.postDateGMT = date;
     */
    postDoc.postDateGMT = self.dateField.objectValue;
    postDoc.postName = self.slugField.stringValue;
    postDoc.postPassword = self.passwordField.stringValue;
    postDoc.isSticky = [NSNumber numberWithBool:self.isStickyButton.state];
    postDoc.postContent = editController.html;
    postDoc.commentStatus = [self.discussionCommentsMatrix.selectedCell title].lowercaseString;
    postDoc.pingStatus = [self.discussionPingsMatrix.selectedCell title].lowercaseString;

    // Post Thumbnail
    if (self.featuredImageView.imageID) {
        /*id mediaDict = oldPost.postThumbnail;
        NSInteger attachmentID = -1;
        if ([mediaDict isKindOfClass:[NSDictionary class]]) {
            attachmentID = [[mediaDict objectForKey:@"attachment_id"] integerValue];
        }
        if (self.featuredImageView.imageID.integerValue != attachmentID) {
            postDoc.postThumbnail = [NSNumber numberWithInteger:self.featuredImageView.imageID.integerValue];
        }*/
        postDoc.postThumbnail = [NSNumber numberWithInteger:self.featuredImageView.imageID.integerValue];
    } else {
        postDoc.postThumbnail = @0;
    }

    // Custom Fields
    NSArray *allFields = [dataManager.customFields arrayByAddingObjectsFromArray:dataManager.deletedCustomFields];
    NSMutableArray *newFields = [NSMutableArray array];
    for (NSDictionary *fieldDict in allFields) {
        if (fieldDict[@"id"] != nil && fieldDict[@"key"] == nil) {
            [newFields addObject:@{@"id":fieldDict[@"id"]}];
        } else if (fieldDict[@"id"] != nil) {
            [newFields addObject:@{@"key":fieldDict[@"key"], @"value":fieldDict[@"value"], @"id":fieldDict[@"id"]}];
        } else {
            [newFields addObject:@{@"key":fieldDict[@"key"], @"value":fieldDict[@"value"]}];
        }
    }
    postDoc.customFields = newFields;

    // Categories and Tags
    NSMutableDictionary *taxonomyDict = [NSMutableDictionary dictionary];
    if (![self.tagsTokenField.stringValue isEqualToString:@""]) {
        [taxonomyDict setObject:self.tagsTokenField.objectValue forKey:@"post_tag"];
    }
    NSMutableArray *selectedCategories = [NSMutableArray array];
    for (NSMenuItem *item in self.categoriesPopUpButton.itemArray) {
        if (item.state == NSOnState) {
            [selectedCategories addObject:item.title];
        }
    }
    [taxonomyDict setObject:selectedCategories forKey:@"category"];
    postDoc.termsNames = taxonomyDict;

    return postDoc;
}

- (IBAction)commitPost:(id)sender {
    //LSDocument *postDoc = [self createDocument];
    [dataManager saveDraft:nil];
    
    LSDocument *postDoc = self.selectedDocument;
    
    // Change all image src to URL
    DOMDocument *domDoc = [editController.webView mainFrameDocument];
    DOMNodeList *imgList = [domDoc getElementsByTagName:@"img"];
    for (int i = 0; i < [imgList length]; i++) {
        DOMElement *element = (DOMElement *)[imgList item:i];
        NSString *src = [element getAttribute:@"src"];
        
        if ([src rangeOfString:@"/media-local/"].location != NSNotFound) {
            NSURL *url = [NSURL fileURLWithPath:src];
            NSMutableDictionary *imageDict = [NSMutableDictionary dictionary];
            
            NSString *imageName = [src lastPathComponent];
            [imageDict setObject:imageName forKey:@"name"];
            [imageDict setObject:[mediaController mimeTypeForFile:imageName] forKey:@"type"];
            [imageDict setObject:[NSNumber numberWithBool:NO] forKey:@"overwrite"];
            
            NSData *data = [[[NSData alloc] initWithContentsOfURL:url] autorelease];
            [imageDict setObject:data forKey:@"bits"];
            
            [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.uploadFile" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, imageDict]];
            
        } else {
            for (IKBBrowserItem *item in dataManager.media) {
                if ([item.fileName.lastPathComponent isEqualToString:src.lastPathComponent]) {
                    [element setAttribute:@"src" value:item.URL.absoluteString];
                    break;
                }
            }
        }
    }
    
    postDoc.postContent = domDoc.body.innerHTML;
    
    if ([self.selectedDocumentID isEqualToString:@"-1"]) {
        // First commit
        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.newPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, postDoc.dictionary]];
        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getMediaLibrary" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getPosts" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
    } else {
        if ([self.tagsTokenField.stringValue isEqualToString:@""]) {
            // We use a MetaWeblog call here to clear all tags because there doesn't seem
            // to be a way to do this with the Wordpress API.
            [xmlrpcManager queueXMLRPCRequestUsingMethod:@"metaWeblog.editPost" withParameters:@[self.selectedDocumentID, accountsController.username, accountsController.password, @{@"mt_keywords" : @""}, @(YES)]];
        }
        
        //NSLog(@"%@", postDoc.dictionary);

        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.editPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, self.selectedDocumentID, postDoc.dictionary]];
        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getMediaLibrary" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
        [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, self.selectedDocumentID]];
        
    }

    [xmlrpcManager startProcessingQueue];

}

#pragma mark -

- (IBAction)togglePostInfoSidebar:(id)sender {
    if ([splitView isSubviewCollapsed:[[splitView subviews] objectAtIndex:1]]) {
        // Uncollapse
        NSView *left  = [[splitView subviews] objectAtIndex:0];
        NSView *right = [[splitView subviews] objectAtIndex:1];
        [right setHidden:NO];
        CGFloat dividerThickness = [splitView dividerThickness];
        // get the different frames
        NSRect leftFrame = [left frame];
        NSRect rightFrame = [right frame];
        // Adjust left frame size
        leftFrame.size.width = (leftFrame.size.width-rightFrame.size.width-dividerThickness);
        rightFrame.origin.x = leftFrame.size.width + dividerThickness;
        [left setFrameSize:leftFrame.size];
        [right setFrame:rightFrame];
        [splitView display];
    } else {
        // Collapse
        NSView *right = [[splitView subviews] objectAtIndex:1];
        NSView *left  = [[splitView subviews] objectAtIndex:0];
        NSRect leftFrame = [left frame];
        NSRect overallFrame = [splitView frame]; //???
        [right setHidden:YES];
        [left setFrameSize:NSMakeSize(overallFrame.size.width,leftFrame.size.height)];
        [splitView display];
    }
}

- (IBAction)closeSheet:(id)sender {
    [NSApp stopModalWithCode:[sender tag]];
}

- (void)savePostInfo {
    [dataManager saveDraft:nil];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.2];
}

- (IBAction)popUpSelected:(id)sender {
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
}

- (IBAction)buttonSelected:(id)sender {
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
}

- (void)selectFirstCategory {
	for (NSMenuItem *item in [self.categoriesPopUpButton itemArray]) {
		if ([item state] == NSOnState) {
			[self.categoriesPopUpButton selectItem:item];
			return;
		}
	}
	[self.categoriesPopUpButton selectItemAtIndex:-1];
}

- (IBAction)categorySelected:(id)sender {
    [self popUpSelected:sender];
	NSMenuItem *selectedItem = [self.categoriesPopUpButton selectedItem];
	if ([[selectedItem title] isEqualToString:@"Add category…"]) {
        [self.categoryNameField setStringValue:@""];
        [NSApp beginSheet:categoryWindow modalForWindow:[sender window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        NSInteger code = [NSApp runModalForWindow:categoryWindow];

        if (code == 0 || [[self.categoryNameField stringValue] isEqualToString:@""] || [dataManager.categories containsObject:[self.categoryNameField stringValue]]) {
            [self selectFirstCategory];
        } else {
			[dataManager.categories addObject:[self.categoryNameField stringValue]];
			[dataManager.categories sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            [self.postsOutlineViewDelegate reloadTerms];
        }
        [NSApp endSheet:categoryWindow];
        [categoryWindow orderOut:self];
        return;
	}
	if ([selectedItem state] == NSOnState)
		[selectedItem setState:NSOffState];
	else
		[selectedItem setState:NSOnState];
    [self selectFirstCategory];
}

- (IBAction)addCustomField:(id)sender {
    [self.customFieldKeyField setStringValue:@""];
    [self.customFieldValueField setStringValue:@""];
    [customFieldWindow makeFirstResponder:self.customFieldKeyField];
    [NSApp beginSheet:customFieldWindow modalForWindow:[sender window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    NSInteger code = [NSApp runModalForWindow:customFieldWindow];

    if (code == 0 || [[self.customFieldKeyField stringValue] isEqualToString:@""] || [[self.customFieldValueField stringValue] isEqualToString:@""]) {
    } else {
        [dataManager addCustomField:[NSMutableDictionary dictionaryWithDictionary:@{@"key" : [self.customFieldKeyField stringValue], @"value" : [self.customFieldValueField stringValue]}]];
        [self.customFieldsTableView reloadData];
    }

    [NSApp endSheet:customFieldWindow];
    [customFieldWindow orderOut:self];
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
    
}

- (IBAction)removeCustomField:(id)sender {
    if ([self.customFieldsTableView selectedRow] >= 0 && [self.customFieldsTableView selectedRow] < [dataManager.customFields count]) {
        NSMutableDictionary *customField = [dataManager.customFields objectAtIndex:[self.customFieldsTableView selectedRow]];
        if ([customField objectForKey:@"id"] == nil) {
            [dataManager.customFields removeObject:customField];
        } else {
            [customField removeObjectForKey:@"key"];
            [customField removeObjectForKey:@"value"];
            [dataManager.deletedCustomFields addObject:customField];
            [dataManager.customFields removeObject:customField];
        }
    }
    [self.customFieldsTableView reloadData];
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", substring];
	return [dataManager.tags filteredArrayUsingPredicate:predicate];
}

- (IBAction)addFeaturedImage:(id)sender {
    [mediaController setMode:MediaPanelChooseMode];
    [mediaController showMediaPanelForWindow:[sender window]];
}

- (IBAction)clearFeaturedImage:(id)sender {
    [self.featuredImageView setImage:nil];
    self.featuredImageView.imageID = nil;
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
}

- (IBAction)discussionMatrixAction:(id)sender {
    [self performSelector:@selector(savePostInfo) withObject:nil afterDelay:0.1];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        if (self.selectedDocument.docType == DocumentDraftType) {
            [dataManager deleteSelectedDraft];
        } else if (self.selectedDocument.docType == DocumentPostType) {
            [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.deletePost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, self.selectedDocumentID]];
            [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getPosts" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
            [xmlrpcManager startProcessingQueue];
        }
        [self.postsOutlineView deselectAll:nil];
    }
}

- (IBAction)deletePost:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Delete \"%@\"?", self.selectedDocumentTitle] defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Deleting posts is permanant and you cannot undo this action."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[splitView window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)newPost:(id)sender {
    NSString *fileName = [dataManager createNewDraft];

    for (int i = 0; i < self.postsOutlineView.numberOfRows; i++) {
        id item = [self.postsOutlineView itemAtRow:i];
        if ([item isKindOfClass:[LSDocument class]]) {
            LSDocument *doc = (LSDocument *)item;
            if ([doc.fileName isEqualToString:fileName]) {
                [self.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
                return;
            }
        }
    }

    /*NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    [postDict setObject:@"New Post" forKey:@"post_title"];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.newPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, postDict]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getPosts" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
    [xmlrpcManager startProcessingQueue];*/

    
}

@end
