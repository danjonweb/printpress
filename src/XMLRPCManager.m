//
//  XMLRPCDelegate.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/8/12.
//
//

#import "XMLRPCManager.h"
#import "AccountsController.h"
#import "DataManager.h"
#import "PostsController.h"
#import "MediaController.h"
#import "EditController.h"
#import "LSDocument.h"
#import "AFHTTPRequestOperation.h"

#import "XMLRPCConnection.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnectionManager.h"


NSString *XMLRPCBeginQueueNotification = @"XMLRPCBeginQueueNotification";
NSString *XMLRPCEndQueueNotification = @"XMLRPCEndQueueNotification";

@implementation XMLRPCManager

- (void)start {
    self.requestQueue = [NSMutableArray array];
    self.postID = nil;
}

- (void)stop {
    self.requestQueue = nil;
    self.postID = nil;
}

#pragma mark -

- (void)processQueue {
    if (self.requestQueue.count > 0) {
        XMLRPCRequest *request = [self.requestQueue objectAtIndex:0];
        XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
        [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
        [self.requestQueue removeObjectAtIndex:0];
        return;
    }
    [postsController.postsOutlineViewDelegate reloadSelectedPostAndContent:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:XMLRPCEndQueueNotification object:nil];
}

- (void)queueXMLRPCRequestUsingMethod:(NSString *)method withParameters:(NSArray *)params {
	NSURL *URL = [NSURL URLWithString:accountsController.xmlrpcURL];
	XMLRPCRequest *request = [[[XMLRPCRequest alloc] initWithURL:URL] autorelease];
	[request setMethod:method withParameters:params];
	[self.requestQueue addObject:request];
}

- (void)startProcessingQueue {
    if (IN_TRIAL_MODE) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Trial Mode"];
        [alert setInformativeText:@"Thank you for trying Printpress. In trial mode, Printpress can create drafts but cannot connect to a WordPress blog. Click Open App Store to purchase the full version."];
        [alert addButtonWithTitle:@"Continue"];
        [alert addButtonWithTitle:@"Open App Store"];
        NSInteger result = [alert runModal];
        if (result == NSAlertSecondButtonReturn) {
            [[NSWorkspace sharedWorkspace] openURL:
             [NSURL URLWithString:@"macappstore://itunes.apple.com/us/app/printpress-wordpress-blog/id594094031?mt=12"]];
        }
        [[self requestQueue] removeAllObjects];
        [self processQueue];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:XMLRPCBeginQueueNotification object:nil];
        [self processQueue];
    }
}

# pragma mark -

- (void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response {
    if (response.isFault) {
		//NSLog(@"Fault code: %@", response.faultCode);
		//NSLog(@"Fault string: %@", response.faultString);
        //[self processQueue];
        [errorTextField setStringValue:[response faultString]];
        [NSApp beginSheet:errorWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [NSApp runModalForWindow:errorWindow];
        [NSApp endSheet:errorWindow];
        [errorWindow orderOut:self];
        [self.requestQueue removeAllObjects];
        [self processQueue];
	} else {
        if ([request.method isEqualToString:@"wp.newPost"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostCreatedNotification" object:nil];
            [dataManager deleteSelectedDraft];
            self.postID = response.object;
        } else if ([request.method isEqualToString:@"wp.deletePost"]) {
            
        } else if ([request.method isEqualToString:@"wp.getPosts"]) {
            //NSLog(@"!!!!! wp.getPosts: %@", response.object);
            [dataManager loadPosts:response.object];
            [postsController.postsOutlineView reloadItem:nil reloadChildren:YES];
            [postsController.postsOutlineView expandItem:nil expandChildren:YES];
            if (self.postID) {
                [postsController selectPostWithID:self.postID];
                [editController activate];
                self.postID = nil;
            }
        } else if ([request.method isEqualToString:@"wp.getTerms"]) {
            for (NSDictionary *termDict in response.object) {
                NSString *name = [termDict objectForKey:@"name"];
                if ([[termDict objectForKey:@"taxonomy"] isEqualToString:@"post_tag"]) {
                    [dataManager addTag:name];
                }
                if ([[termDict objectForKey:@"taxonomy"] isEqualToString:@"category"]) {
                    [dataManager addCategory:name];
                }
            }
            [dataManager cacheObject:dataManager.categories toFolder:@"categories"];
        } else if ([request.method isEqualToString:@"wp.getAuthors"]) {
            for (NSDictionary *authorDict in response.object) {
                [dataManager addAuthor:[authorDict objectForKey:@"display_name"] withID:[[authorDict objectForKey:@"user_id"] integerValue]];
            }
            [dataManager cacheObject:dataManager.authors toFolder:@"authors"];
        } else if ([request.method isEqualToString:@"wp.getMediaLibrary"]) {
            //NSLog(@"!!!!! wp.getMediaLibrary: %@", response);
            [mediaController handleGetMediaLibraryResponseWithData:response.object];
        } else if ([request.method isEqualToString:@"wp.uploadFile"]) {
            NSDictionary *imageDict = response.object;
            NSString *path = [[dataManager localMediaFolder] stringByAppendingPathComponent:imageDict[@"file"]];
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            
            for (XMLRPCRequest *request in self.requestQueue) {
                if ([request.method isEqualToString:@"wp.editPost"] || [request.method isEqualToString:@"wp.newPost"]) {
                    
                    DOMDocument *domDoc = [editController.webView mainFrameDocument];
                    DOMNodeList *imgList = [domDoc getElementsByTagName:@"img"];
                    for (int i = 0; i < [imgList length]; i++) {
                        DOMElement *element = (DOMElement *)[imgList item:i];
                        NSString *src = [element getAttribute:@"src"];
                        if ([src.lastPathComponent isEqualToString:imageDict[@"file"]]) {
                            [element setAttribute:@"src" value:imageDict[@"url"]];
                        }
                    }
                    
                    LSDocument *postDoc = postsController.selectedDocument;
                    postDoc.postContent = domDoc.body.innerHTML;
                    
                    if ([request.method isEqualToString:@"wp.editPost"])
                        [request setMethod:@"wp.editPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, postsController.selectedDocumentID, postDoc.dictionary]];
                    if ([request.method isEqualToString:@"wp.newPost"])
                        [request setMethod:@"wp.newPost" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, postDoc.dictionary]];
                    
                    break;
                }
            }
        } else if ([request.method isEqualToString:@"wp.editPost"]) {
            [[postsController.postsOutlineView window] setDocumentEdited:NO];
            if (postsController.selectedDocument.docType == DocumentDraftType)
                [dataManager deleteSelectedDraft];
        } else if ([request.method isEqualToString:@"wp.getPost"]) {
            for (int i = 0; i < dataManager.posts.count; i++) {
                LSDocument *postDoc = [dataManager.posts objectAtIndex:i];
                if ([postDoc.postID isEqualToString:response.object[@"post_id"]]) {
                    LSDocument *newPostDoc = [LSDocument documentWithDictionary:response.object];
                    [dataManager.posts replaceObjectAtIndex:i withObject:newPostDoc];
                    [postsController.postsOutlineView reloadItem:nil reloadChildren:YES];
                    break;
                }
            }
            [self performSelector:@selector(selectPostWithID:) withObject:response.object[@"post_id"] afterDelay:0.1];
        }
        [self processQueue];
	}
}

- (void)selectPostWithID:(NSString *)postID {
    [mainWindow makeFirstResponder:postsController.postsOutlineView];
    [postsController selectPostWithID:postID];
    [editController activate];
}

- (void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error {
    /*[errorTextField setStringValue:@"A connection error occurred. Check your account settings and try again."];
    [NSApp beginSheet:errorWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    [NSApp runModalForWindow:errorWindow];
    [NSApp endSheet:errorWindow];
    [errorWindow orderOut:self];
    [self.requestQueue removeAllObjects];
    self.shouldGoToAccountsAfterError = YES;*/

    [dataManager loadCategoriesFromCache];
    [dataManager loadAuthorsFromCache];
    [mediaController loadMediaFromCache];

    [self.requestQueue removeAllObjects];
    [self processQueue];
}

- (BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return NO;
}

- (void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

#pragma mark -

- (IBAction)closeSheet:(id)sender {
    [NSApp stopModalWithCode:[sender tag]];
}

@end
