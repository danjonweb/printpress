//
//  CustomFieldTableViewDelegate.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/14/12.
//
//

#import <Foundation/Foundation.h>

@class DataManager;
@class PostsController;

@interface CustomFieldTableViewDelegate : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet DataManager*           dataManager;
    IBOutlet PostsController*       postsController;
}

@end
