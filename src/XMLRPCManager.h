//
//  XMLRPCDelegate.h
//  Blog Creature
//
//  Created by Daniel Weber on 9/8/12.
//
//

#import <Foundation/Foundation.h>
#import "XMLRPCConnectionDelegate.h"


extern NSString *XMLRPCBeginQueueNotification;
extern NSString *XMLRPCEndQueueNotification;

@class AccountsController, DataManager, PostsController, MediaController, EditController;

@interface XMLRPCManager : NSObject <XMLRPCConnectionDelegate, NSURLConnectionDataDelegate> {
    IBOutlet AccountsController*    accountsController;
    IBOutlet DataManager*           dataManager;
    IBOutlet PostsController*       postsController;
    IBOutlet MediaController*       mediaController;
    IBOutlet EditController*        editController;

    IBOutlet NSWindow*              mainWindow;
    IBOutlet NSWindow*              errorWindow;
    IBOutlet NSTextField*           errorTextField;

    NSMutableData *postData;
}

- (void)start;
- (void)stop;
- (void)queueXMLRPCRequestUsingMethod:(NSString *)method withParameters:(NSArray *)params;
- (void)startProcessingQueue;

@property (nonatomic, retain) NSMutableArray *requestQueue;
@property (nonatomic, copy) NSString *postID;

@end
