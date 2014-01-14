//
//  PostsOutlineViewDelegate.m
//  Printpress
//
//  Created by Daniel Weber on 12/18/12.
//
//

#import "PostsOutlineViewDelegate.h"
#import "DataManager.h"
#import "PostsController.h"
#import "EditController.h"
#import "IKBBrowserItem.h"
#import "LSFeaturedImageView.h"
#import "LSDocument.h"
#import "LSTextFieldCell.h"
#import "NSMenu+Utils.h"
#import <WebKit/WebKit.h>

@implementation PostsOutlineViewDelegate

- (void)start {
    postsController.postsOutlineView.target = self;
    postsController.postsOutlineView.action = @selector(singleClickAction:);
    postsController.postsOutlineView.allowsEmptySelection = YES;
    [dataManager loadDrafts];
}

- (void)stop {
}

- (void)singleClickAction:(id)sender {
    NSInteger clickedRow = [sender clickedRow];
    if (clickedRow < 0) {
        if (postsController.postsOutlineView.window.isDocumentEdited) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PostSelectionWillChangeNotification" object:[NSNumber numberWithInteger:-1]];
        } else {
            [postsController.postsOutlineView deselectAll:nil];
        }
    }
}

- (void)postDoubleClicked:(id)sender {
    if ([postsController.postsOutlineView selectedRow] >= 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDoubleClickedNotification" object:nil];
}

#pragma mark -

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        if (index == 0) return @"Posts";
        if (index == 1) return @"Drafts";
    }
    if ([item isKindOfClass:[NSString class]]) {
        if ([item isEqualToString:@"Posts"])
            return [dataManager.posts objectAtIndex:index];
        if ([item isEqualToString:@"Drafts"])
            return [dataManager.drafts objectAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil)
        return NO;
    if ([item isKindOfClass:[NSString class]]) {
        return YES;
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return 2;

    if ([item isKindOfClass:[NSString class]]) {
        if ([item isEqualToString:@"Posts"])
            return dataManager.posts.count;
        if ([item isEqualToString:@"Drafts"])
            return dataManager.drafts.count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if (item == nil)
        return nil;
    if ([item isKindOfClass:[NSString class]]) {
        return item;
    }
    if ([item isKindOfClass:[LSDocument class]]) {
        return item;
    }
    return @"";
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if (item == nil)
        return NO;
    if ([item isKindOfClass:[NSString class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[NSString class]])
        return NO;
    if (postsController.postsOutlineView.window.isDocumentEdited) {
        NSInteger row = [postsController.postsOutlineView rowForItem:item];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostSelectionWillChangeNotification" object:[NSNumber numberWithInteger:row]];
    } else {
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    LSTextFieldCell *myCell = (LSTextFieldCell *)cell;

    if ([item isKindOfClass:[NSString class]]) {
        myCell.title = item;
        myCell.previousTitle = @"";
    } else if ([item isKindOfClass:[LSDocument class]]) {
        LSDocument *postDoc = (LSDocument *)item;
        myCell.title = postDoc.postTitle;
        NSString *previousTitle = @"";
        for (LSDocument *doc in dataManager.posts) {
            if ([doc.postID isEqualToString:postDoc.postID] && ![doc.postTitle isEqualToString:postDoc.postTitle]) {
                previousTitle = doc.postTitle;
                break;
            }
        }
        myCell.previousTitle = previousTitle;
    }

    if ([self outlineView:outlineView isGroupItem:item]) {
        myCell.isIndented = NO;
        myCell.isGroupItem = YES;
    } else {
        myCell.isIndented = YES;
        myCell.isGroupItem = NO;
    }
}


#pragma mark -

- (void)reloadTerms {
    LSDocument *postDoc = postsController.selectedDocument;
    [postsController.categoriesPopUpButton removeAllItems];
    [postsController.tagsTokenField setStringValue:@""];

    [postsController.categoriesPopUpButton addItemsWithTitles:dataManager.categories];
    [postsController.categoriesPopUpButton selectItemAtIndex:-1];
    
    if (postDoc.terms) {
        // Server
        for (NSDictionary *termDict in postDoc.terms) {
            if ([termDict[@"taxonomy"] isEqualToString:@"post_tag"]) {
                postsController.tagsTokenField.stringValue = [NSString stringWithFormat:@"%@,%@", postsController.tagsTokenField.stringValue, termDict[@"name"]];
            } else if ([termDict[@"taxonomy"] isEqualToString:@"category"]) {
                for (NSMenuItem *menuItem in postsController.categoriesPopUpButton.menu.itemArray) {
                    if (![menuItem.title isEqualToString:termDict[@"name"]])
                        continue;
                    [menuItem setState:NSOnState];
                    NSMutableAttributedString *title = [[[NSMutableAttributedString alloc] initWithString:[menuItem title]] autorelease];
                    [title addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica-Bold" size:14.0] range:NSMakeRange(0, [title length])];
                    [menuItem setAttributedTitle:title];
                    if (postsController.categoriesPopUpButton.indexOfSelectedItem == -1)
                        [postsController.categoriesPopUpButton selectItem:menuItem];
                    break;
                }
            }
        }
    } else if (postDoc.termsNames) {
        // Draft
        for (NSString *category in postDoc.termsNames[@"category"]) {
            NSMenuItem *menuItem = [postsController.categoriesPopUpButton itemWithTitle:category];
            if (!menuItem)
                continue;
            [menuItem setState:NSOnState];
            NSMutableAttributedString *title = [[[NSMutableAttributedString alloc] initWithString:[menuItem title]] autorelease];
            [title addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica-Bold" size:14.0] range:NSMakeRange(0, [title length])];
            [menuItem setAttributedTitle:title];
            if (postsController.categoriesPopUpButton.indexOfSelectedItem == -1)
                [postsController.categoriesPopUpButton selectItem:menuItem];
        }

        postsController.tagsTokenField.objectValue = postDoc.termsNames[@"post_tag"];
    }
    [postsController.categoriesPopUpButton.menu addItem:[NSMenuItem separatorItem]];
    [postsController.categoriesPopUpButton addItemWithTitle:@"Add category…"];
}

- (void)loadPostFromDocument:(LSDocument *)postDoc reloadContent:(BOOL)shouldReloadContent {
    postsController.titleField.stringValue = postDoc.postTitle;
    postsController.slugField.stringValue = postDoc.postName;
    postsController.excerptField.stringValue = postDoc.postExcerpt;
    postsController.dateField.objectValue = postDoc.postDateGMT;
    postsController.isStickyButton.state = postDoc.isSticky.integerValue;
    postsController.passwordField.stringValue = postDoc.postPassword;

    // Post Author
    for (NSDictionary *authorDict in dataManager.authors) {
        [postsController.authorPopUpButton addItemWithTitle:[authorDict objectForKey:@"display_name"]];
        [[postsController.authorPopUpButton lastItem] setTag:[[authorDict objectForKey:@"user_id"] integerValue]];
    }
    [postsController.authorPopUpButton selectItemWithTag:postDoc.postAuthor.integerValue];

    // Post Format
    [postsController.formatPopUpButton addItemsWithTitles:@[@"standard", @"aside", @"gallery", @"link", @"image", @"quote", @"status", @"video", @"audio", @"chat"]];
    [postsController.formatPopUpButton selectItemWithTitle:postDoc.postFormat];

    // Categories and Tags
    [self reloadTerms];

    // Post Status
    if ([postDoc.postStatus isEqualToString:@"publish"])
        [postsController.postStatusPopUpButton selectItemAtIndex:0];
    if ([postDoc.postStatus isEqualToString:@"draft"])
        [postsController.postStatusPopUpButton selectItemAtIndex:1];
    if ([postDoc.postStatus isEqualToString:@"pending"])
        [postsController.postStatusPopUpButton selectItemAtIndex:2];
    if ([postDoc.postStatus isEqualToString:@"private"])
        [postsController.postStatusPopUpButton selectItemAtIndex:3];

    // Custom Fields
    NSArray *fieldArray = postDoc.customFields;
    [dataManager removeAllCustomFields];
    for (NSDictionary *fieldDict in fieldArray) {
        if ([[fieldDict[@"key"] substringToIndex:1] isEqualToString:@"_"])
            continue;
        NSDictionary *customField = nil;
        if (fieldDict[@"key"] && fieldDict[@"value"] && fieldDict[@"id"]) {
            customField = @{@"key":fieldDict[@"key"], @"value":fieldDict[@"value"], @"id":fieldDict[@"id"]};
        } else if (fieldDict[@"key"] && fieldDict[@"value"]) {
            customField = @{@"key":fieldDict[@"key"], @"value":fieldDict[@"value"]};
        } else if (fieldDict[@"id"]) {
            customField = @{@"id":fieldDict[@"id"]};
        }
        [dataManager addCustomField:[customField.mutableCopy autorelease]];
    }
    [postsController.customFieldsTableView reloadData];

    // Featured Image
    if ([postDoc.postThumbnail isKindOfClass:[NSDictionary class]]) {
        // Server
        NSDictionary *imageDict = postDoc.postThumbnail;
        for (IKBBrowserItem *item in dataManager.media) {
            if ([item.imageID isEqualToString:imageDict[@"attachment_id"]]) {
                [postsController.featuredImageView setImage:item.image];
                postsController.featuredImageView.imageID = item.imageID;
            }
        }
    } else if ([postDoc.postThumbnail isKindOfClass:[NSNumber class]]) {
        // Draft
        for (IKBBrowserItem *item in dataManager.media) {
            if ([item.imageID isEqualToString:[postDoc.postThumbnail stringValue]]) {
                [postsController.featuredImageView setImage:item.image];
                postsController.featuredImageView.imageID = item.imageID;
            }
        }
    }
    
    // Discussion
    [postsController.discussionCommentsMatrix setEnabled:NO];
    [postsController.discussionPingsMatrix setEnabled:NO];
    if ([postDoc.commentStatus.lowercaseString isEqualToString:@"open"])
        [postsController.discussionCommentsMatrix selectCellAtRow:0 column:0];
    if ([postDoc.commentStatus.lowercaseString isEqualToString:@"closed"])
        [postsController.discussionCommentsMatrix selectCellAtRow:0 column:1];
    if ([postDoc.pingStatus.lowercaseString isEqualToString:@"open"])
        [postsController.discussionPingsMatrix selectCellAtRow:0 column:0];
    if ([postDoc.pingStatus.lowercaseString isEqualToString:@"closed"])
        [postsController.discussionPingsMatrix selectCellAtRow:0 column:1];
    [postsController.discussionCommentsMatrix setEnabled:YES];
    [postsController.discussionPingsMatrix setEnabled:YES];
    
    [postsController.authorPopUpButton.menu adjustLineHeightFromIndex:0];
    [postsController.formatPopUpButton.menu adjustLineHeightFromIndex:0];
    [postsController.postStatusPopUpButton.menu adjustLineHeightFromIndex:0];
    [postsController.categoriesPopUpButton.menu adjustLineHeightFromIndex:0];

    if (shouldReloadContent) {
        editController.html = postDoc.postContent;
        [editController activate];
    }
}

#pragma mark -

- (void)reloadSelectedPostAndContent:(BOOL)shouldReloadContent {
    NSResponder *firstResponer = [NSApp mainWindow].firstResponder;
    NSRange selectedRange = NSMakeRange(0, 0);

    if ([firstResponer isKindOfClass:[NSTextView class]]) {
        NSText *fieldEditor = [[NSApp mainWindow] fieldEditor:YES forObject:firstResponer];
        selectedRange = fieldEditor.selectedRange;
    }
    
    [postsController resetPostInformation];
    if ([postsController.postsOutlineView selectedRow] < 0) {
        [postsController setPostInformationEditable:NO];
    } else {
        [self loadPostFromDocument:postsController.selectedDocument reloadContent:shouldReloadContent];
        [postsController setPostInformationEditable:YES];
    }

    if ([firstResponer isKindOfClass:[NSTextView class]]) {
        NSText *fieldEditor = [[NSApp mainWindow] fieldEditor:YES forObject:firstResponer];
        if (selectedRange.location >= fieldEditor.string.length) {
            [fieldEditor setSelectedRange:NSMakeRange(selectedRange.location, 0)];
        } else {
            [fieldEditor setSelectedRange:selectedRange];
        }
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostSelectionDidChangeNotification" object:nil];
    [postsController.deletePostButton setEnabled:postsController.isDocumentSelected];
    [self reloadSelectedPostAndContent:YES];
    //NSLog(@"%@", postsController.selectedDocument.dictionary);
}

- (void)selectPostWithID:(NSString *)postID {
    for (int i = 0; i < postsController.postsOutlineView.numberOfRows; i++) {
        id item = [postsController.postsOutlineView itemAtRow:i];
        if ([item isKindOfClass:[LSDocument class]]) {
            LSDocument *document = (LSDocument *)item;
            if ([document.postID isEqualToString:postID]) {
                [postsController.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
                break;
            }
        }
    }
}

@end
