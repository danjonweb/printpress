//
//  AccountsDelegate.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/7/12.
//
//

#import <Foundation/Foundation.h>


@class DataManager, XMLRPCManager, PostsController;

@interface AccountsController : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    NSMutableArray *accounts;
    NSMutableArray *drafts;

    IBOutlet NSTableView *accountsTableView;
    IBOutlet NSButton *accountsRemoveButton;
    IBOutlet NSTextField *accountsNameField;
    IBOutlet NSTextField *accountsURLTextField;
    IBOutlet NSTextField *accountsUsernameTextField;
    IBOutlet NSSecureTextField *accountsPasswordTextField;
    IBOutlet NSTextField *accountsBlogIDTextField;
    IBOutlet NSTextField *accountsMaxPostsTextField;
    IBOutlet NSButton *accountsAutoLoginButton;
    IBOutlet NSButton *loadPostsButton;

    IBOutlet DataManager*       dataManager;
    IBOutlet XMLRPCManager*     xmlrpcManager;
    IBOutlet PostsController*   postsController;
}

- (void)start;
- (void)stop;
- (void)selectFirstResponder;
- (BOOL)shouldAutoLogin;
- (void)selectAutoLoginAccount;
- (void)refreshSelectedBlog;

@property (nonatomic, readonly) NSString *xmlrpcURL;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, readonly) NSString *blogID;
@property (nonatomic, readonly) NSString *blogUUID;
@property (nonatomic, readonly) NSString *maxPosts;

@property (nonatomic, copy) NSString *lastAccountLoaded;

@end
