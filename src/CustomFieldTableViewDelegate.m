//
//  CustomFieldTableViewDelegate.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/14/12.
//
//

#import "CustomFieldTableViewDelegate.h"
#import "DataManager.h"
#import "PostsController.h"

@implementation CustomFieldTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [dataManager.customFields count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [[dataManager.customFields objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSMutableDictionary *customField = [dataManager.customFields objectAtIndex:row];
    [customField setObject:object forKey:[tableColumn identifier]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = [notification object];
    if ([tableView selectedRow] >= 0) {
        [postsController.customFieldRemoveButton setEnabled:YES];
    } else {
        [postsController.customFieldRemoveButton setEnabled:NO];
    }
}

@end
