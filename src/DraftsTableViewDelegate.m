//
//  BrowseVersionsTableViewDelegate.m
//  Blog Creature
//
//  Created by Daniel Weber on 11/18/12.
//
//

#import "DraftsTableViewDelegate.h"
#import "DataManager.h"
#import "EditController.h"
#import "PostsController.h"

@implementation DraftsTableViewDelegate

- (void)awakeFromNib {
    self.drafts = [[[NSMutableArray alloc] init] autorelease];
    [self.draftContentWebView setDrawsBackground:NO];
    [self.draftContentWebView setUIDelegate:self];
    [self.draftContentWebView setEditingDelegate:self];
    [self.draftContentWebView setPolicyDelegate:self];
}

- (void)dealloc {
    self.drafts = nil;
    self.draftsDirectory = nil;
    [super dealloc];
}

- (void)reset {
    [self tableViewSelectionDidChange:nil];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    // disable right-click context menu
    return nil;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSUInteger actionType = [[actionInformation objectForKey:WebActionNavigationTypeKey] unsignedIntValue];
    if (actionType == WebNavigationTypeLinkClicked) {

    } else {
        [listener use];
    }
}

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag {
    // disable text selection
    return NO;
}

- (IBAction)deleteDraft:(id)sender {
    /*NSDictionary *draftDict = [self.drafts objectAtIndex:[self.draftsTableView selectedRow]];
    NSString *fileName = [draftDict objectForKey:@"path"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:[self.draftsDirectory stringByAppendingPathComponent:fileName] error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return;
    }
    [self loadDraftsInPath:self.draftsDirectory];
    [self tableViewSelectionDidChange:nil];*/
}

- (NSString *)draftContent {
    NSInteger selectedRow = [self.draftsTableView selectedRow];
    if (selectedRow < 0)
        return nil;
    return [[self.drafts objectAtIndex:selectedRow] objectForKey:@"post_content"];
}

/*- (void)loadDraftsInPath:(NSString *)path {
    self.draftsDirectory = path;
    [self.drafts removeAllObjects];

    NSArray *draftsArray = [editController draftObjectsInPath:path];
    for (NSDictionary *draftDict in draftsArray) {
        if ([draftDict[@"post_id"] isEqualToString:postsController.selectedDocumentID]) {
            [self.drafts addObject:draftDict];
        }
    }

    [self.draftsTableView reloadData];
}*/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.drafts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[self.drafts objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [self.draftsTableView selectedRow];
    if (selectedRow < 0) {
        //[self.draftContentField setStringValue:@""];
        [[self.draftContentWebView mainFrame] loadHTMLString:@"" baseURL:nil];
        [self.deleteDraftsButton setEnabled:NO];
        [self.openDraftButton setEnabled:NO];
    } else {
        //[self.draftContentField setStringValue:[[self.drafts objectAtIndex:selectedRow] objectForKey:@"content"]];
        [[self.draftContentWebView mainFrame] loadHTMLString:[[self.drafts objectAtIndex:selectedRow] objectForKey:@"post_content"] baseURL:nil];
        [self.deleteDraftsButton setEnabled:YES];
        [self.openDraftButton setEnabled:YES];
    }
}

@end
