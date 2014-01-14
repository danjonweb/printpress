//
//  PostsOutlineViewDelegate.h
//  Printpress
//
//  Created by Daniel Weber on 12/18/12.
//
//

#import <Foundation/Foundation.h>

@class DataManager, PostsController, EditController;

@interface PostsOutlineViewDelegate : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet DataManager*           dataManager;
    IBOutlet PostsController*       postsController;
    IBOutlet EditController*        editController;
}


- (void)start;
- (void)stop;
- (void)reloadSelectedPostAndContent:(BOOL)shouldReloadContent;
- (void)reloadTerms;
- (void)selectPostWithID:(NSString *)postID;

@end
