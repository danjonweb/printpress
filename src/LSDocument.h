//
//  LSPost.h
//  Printpress
//
//  Created by Daniel Weber on 12/21/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    DocumentPostType,
    DocumentDraftType
} DocumentType;

@interface LSDocument : NSObject <NSCopying> {

}

@property (nonatomic, copy) NSString *commentStatus;
@property (nonatomic, retain) NSMutableArray *customFields;
@property (nonatomic, copy) NSString *guid;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *menuOrder;
@property (nonatomic, copy) NSString *pingStatus;
@property (nonatomic, copy) NSString *postAuthor;
@property (nonatomic, copy) NSString *postContent;
@property (nonatomic, retain) NSDate *postDate;
@property (nonatomic, retain) NSDate *postDateGMT;
@property (nonatomic, copy) NSString *postExcerpt;
@property (nonatomic, copy) NSString *postFormat;
@property (nonatomic, copy) NSString *postID;
@property (nonatomic, copy) NSString *postMIMEType;
@property (nonatomic, copy) NSString *postModified;
@property (nonatomic, copy) NSString *postModifiedGMT;
@property (nonatomic, copy) NSString *postName;
@property (nonatomic, copy) NSString *postParent;
@property (nonatomic, copy) NSString *postPassword;
@property (nonatomic, copy) NSString *postStatus;
@property (nonatomic, retain) id postThumbnail;
@property (nonatomic, copy) NSString *postTitle;
@property (nonatomic, copy) NSString *postType;
@property (nonatomic, retain) NSNumber *isSticky;
@property (nonatomic, retain) NSMutableArray *terms;
@property (nonatomic, retain) NSDictionary *termsNames;

@property (nonatomic, retain) NSString *fileName;

@property (nonatomic, assign) DocumentType docType;
@property (nonatomic, readonly) NSDictionary *dictionary;

+ (LSDocument *)documentWithDictionary:(NSDictionary *)dict;
+ (LSDocument *)document;


@end
