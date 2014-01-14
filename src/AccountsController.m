//
//  AccountsDelegate.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/7/12.
//
//

#import "AccountsController.h"
#import "DataManager.h"
#import "XMLRPCManager.h"
#import "PostsController.h"
#import "SSKeychain.h"
#import "NSString+UUID.h"

@implementation AccountsController

- (void)selectFirstResponder {
    [[accountsTableView window] makeFirstResponder:accountsTableView];
}

- (void)start {
    self.lastAccountLoaded = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"accounts"]) {
        accounts = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"accounts"]];
    } else {
        accounts = [[NSMutableArray alloc] init];
    }
    drafts = [[NSMutableArray alloc] init];
    [accountsTableView reloadData];
    [self tableViewSelectionDidChange:nil];
}

- (void)stop {
    [accounts release];
    [drafts release];
}

- (void)save {
    [[NSUserDefaults standardUserDefaults] setObject:accounts forKey:@"accounts"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString uniqueString] forKey:@"save"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clear {
    [accountsNameField setStringValue:@""];
    [accountsURLTextField setStringValue:@""];
    [accountsUsernameTextField setStringValue:@""];
    [accountsPasswordTextField setStringValue:@""];
    [accountsMaxPostsTextField setStringValue:@"30"];
    [accountsBlogIDTextField setStringValue:@"1"];
    [accountsAutoLoginButton setState:NSOffState];
}

- (void)load {
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow < 0)
        return;
    NSDictionary *accountDict = [accounts objectAtIndex:selectedRow];
    if ([accountDict objectForKey:@"title"])
        [accountsNameField setStringValue:[accountDict objectForKey:@"title"]];
    if ([accountDict objectForKey:@"url"])
        [accountsURLTextField setStringValue:[accountDict objectForKey:@"url"]];
    if ([accountDict objectForKey:@"user"])
        [accountsUsernameTextField setStringValue:[accountDict objectForKey:@"user"]];
    if ([accountDict objectForKey:@"maxposts"])
        [accountsMaxPostsTextField setStringValue:[accountDict objectForKey:@"maxposts"]];
    if ([accountDict objectForKey:@"blogid"])
        [accountsBlogIDTextField setStringValue:[accountDict objectForKey:@"blogid"]];
    if ([accountDict objectForKey:@"autologin"])
        [accountsAutoLoginButton setState:[[accountDict objectForKey:@"autologin"] boolValue] ? NSOnState : NSOffState];

    //NSString *title = [accountDict objectForKey:@"title"];
    NSString *uuid = [accountDict objectForKey:@"uuid"];
    if (![[accountsUsernameTextField stringValue] isEqualToString:@""]) {
        NSString *password = [SSKeychain passwordForService:[NSString stringWithFormat:@"Printpress: %@", uuid] account:[accountsUsernameTextField stringValue]];
        if (password) {
            [accountsPasswordTextField setStringValue:password];
        }
    }
}

- (void)setControlsEnabled:(BOOL)flag {
    [accountsNameField setEnabled:flag];
    [accountsURLTextField setEnabled:flag];
    [accountsUsernameTextField setEnabled:flag];
    [accountsPasswordTextField setEnabled:flag];
    [accountsMaxPostsTextField setEnabled:flag];
    [accountsBlogIDTextField setEnabled:flag];
    [accountsAutoLoginButton setEnabled:flag];
}

# pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return accounts.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0)
        return nil;
    NSDictionary *accountDict = [accounts objectAtIndex:row];
    return [NSString stringWithFormat:@"%@", [accountDict objectForKey:@"title"]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self clear];
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow < 0) {
        [self setControlsEnabled:NO];
        [accountsRemoveButton setEnabled:NO];
        [loadPostsButton setEnabled:NO];
    } else {
        [self setControlsEnabled:YES];
        [accountsRemoveButton setEnabled:YES];
        [loadPostsButton setEnabled:YES];
        [self load];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountDidChangeNotification" object:nil];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow < 0)
        return;
    NSMutableDictionary *accountDict = [accounts objectAtIndex:selectedRow];
    [accountDict setObject:[accountsNameField stringValue] forKey:@"title"];
    [accountDict setObject:[accountsURLTextField stringValue] forKey:@"url"];
    [accountDict setObject:[accountsUsernameTextField stringValue] forKey:@"user"];
    [accountDict setObject:[accountsMaxPostsTextField stringValue] forKey:@"maxposts"];
    [accountDict setObject:[accountsBlogIDTextField stringValue] forKey:@"blogid"];

    //NSString *title = [accountDict objectForKey:@"title"];
    NSString *uuid = [accountDict objectForKey:@"uuid"];
    if (![[accountsUsernameTextField stringValue] isEqualToString:@""]) {
        [SSKeychain setPassword:[accountsPasswordTextField stringValue] forService:[NSString stringWithFormat:@"Printpress: %@", uuid] account:[accountsUsernameTextField stringValue]];
    }
    [self save];
    [accountsTableView reloadData];
}

- (IBAction)autoLoginClicked:(id)sender {
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow < 0)
        return;
    NSMutableDictionary *accountDict = [accounts objectAtIndex:selectedRow];
    BOOL autoLogin = [sender state] == NSOnState ? YES : NO;
    if (autoLogin) {
        // Set the rest of the accounts to not autologin.
        for (NSMutableDictionary *aDict in accounts) {
            [aDict setObject:[NSNumber numberWithBool:NO] forKey:@"autologin"];
        }
    }
    [accountDict setObject:[NSNumber numberWithBool:autoLogin] forKey:@"autologin"];
    [self save];
}

# pragma mark -

- (IBAction)addAccount:(id)sender {
    NSMutableDictionary *accountDict = [NSMutableDictionary dictionary];
    [accountDict setObject:@"New Blog" forKey:@"title"];
    [accountDict setObject:[NSString uniqueString] forKey:@"uuid"];
    [accounts addObject:accountDict];
    [accountsTableView reloadData];
    
    [self save];
}

- (IBAction)removeAccount:(id)sender {
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow < 0)
        return;
    [accounts removeObjectAtIndex:selectedRow];
    [accountsTableView reloadData];
    [self tableViewSelectionDidChange:nil];

    [self save];
}

# pragma mark -

- (BOOL)shouldAutoLogin {
    for (NSDictionary *aDict in accounts) {
        if ([aDict objectForKey:@"autologin"]) {
            if ([[aDict objectForKey:@"autologin"] boolValue])
                return YES;
        }
    }
    return NO;
}

- (void)selectAutoLoginAccount {
    for (int i = 0; i < [accounts count]; i++) {
        NSDictionary *aDict = [accounts objectAtIndex:i];
        if ([aDict objectForKey:@"autologin"] && [[aDict objectForKey:@"autologin"] boolValue]) {
            [accountsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        }
    }
}

- (NSString *)xmlrpcURL {
    return [accountsURLTextField stringValue];
}

- (NSString *)username {
    return [accountsUsernameTextField stringValue];
}

- (NSString *)password {
    return [accountsPasswordTextField stringValue];
}

- (NSString *)blogID {
    return [accountsBlogIDTextField stringValue];
}

- (NSString *)maxPosts {
    return [accountsMaxPostsTextField stringValue];
}

- (NSString *)blogUUID {
    NSInteger selectedRow = [accountsTableView selectedRow];
    if (selectedRow >= 0) {
        NSDictionary *accountDict = [accounts objectAtIndex:selectedRow];
        return [accountDict objectForKey:@"uuid"];
    }
    return @"";
}

#pragma mark -

- (void)refreshSelectedBlog {
    self.lastAccountLoaded = self.blogUUID;

    [postsController.postsOutlineView deselectAll:nil];
    [dataManager removeAllTags];
    [dataManager removeAllCategories];
    [dataManager removeAllAuthors];

    [dataManager loadDrafts];

    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getPosts" withParameters:@[self.blogID, self.username, self.password, @{@"number":self.maxPosts}]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getTerms" withParameters:@[self.blogID, self.username, self.password, @"category"]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getTerms" withParameters:@[self.blogID, self.username, self.password, @"post_tag"]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getAuthors" withParameters:@[self.blogID, self.username, self.password]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getMediaLibrary" withParameters:@[self.blogID, self.username, self.password]];
    [xmlrpcManager startProcessingQueue];

}

- (IBAction)refreshBlog:(id)sender {
    [self refreshSelectedBlog];
}

@end
