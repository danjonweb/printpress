//
//  LSPost.m
//  Printpress
//
//  Created by Daniel Weber on 12/21/12.
//
//

#import "LSDocument.h"

@implementation LSDocument

+ (LSDocument *)documentWithDictionary:(NSDictionary *)dict {
    return [[[LSDocument alloc] initWithDictionary:dict] autorelease];
}

+ (LSDocument *)document {
    return [[[LSDocument alloc] init] autorelease];
}

- (id)copyWithZone:(NSZone *)zone {
    LSDocument *copy = [[[self class] alloc] init];

    if (copy) {
        // Copy NSObject subclasses
        copy.commentStatus = self.commentStatus;
        copy.customFields = self.customFields;
        copy.guid = self.guid;
        copy.link = self.link;
        copy.menuOrder = self.menuOrder;
        copy.pingStatus = self.pingStatus;
        copy.postAuthor = self.postAuthor;
        copy.postContent = self.postContent;
        copy.postDate = self.postDate;
        copy.postDateGMT = self.postDateGMT;
        copy.postExcerpt = self.postExcerpt;
        copy.postFormat = self.postFormat;
        copy.postID = self.postID;
        copy.postMIMEType = self.postMIMEType;
        copy.postModified = self.postModified;
        copy.postModifiedGMT = self.postModifiedGMT;
        copy.postName = self.postName;
        copy.postParent = self.postParent;
        copy.postPassword = self.postPassword;
        copy.postStatus = self.postStatus;
        copy.postThumbnail = self.postThumbnail;
        copy.postTitle = self.postTitle;
        copy.postType = self.postType;
        copy.isSticky = self.isSticky;
        copy.terms = self.terms;
        copy.termsNames = self.termsNames;
        copy.fileName = self.fileName;
        copy.docType = self.docType;
    }

    return copy;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.commentStatus = dict[@"comment_status"];
        self.customFields = dict[@"custom_fields"];
        self.guid = dict[@"guid"];
        self.link = dict[@"link"];
        self.menuOrder = dict[@"menu_order"];
        self.pingStatus = dict[@"ping_status"];
        self.postAuthor = dict[@"post_author"];
        self.postContent = dict[@"post_content"];
        self.postDate = dict[@"post_date"];
        self.postDateGMT = dict[@"post_date_gmt"];
        self.postExcerpt = dict[@"post_excerpt"];
        self.postFormat = dict[@"post_format"];
        self.postID = dict[@"post_id"];
        self.postMIMEType = dict[@"post_mime_type"];
        self.postModified = dict[@"post_modified"];
        self.postModifiedGMT = dict[@"post_modified_gmt"];
        self.postName = dict[@"post_name"];
        self.postParent = dict[@"post_parent"];
        self.postPassword = dict[@"post_password"];
        self.postStatus = dict[@"post_status"];
        self.postThumbnail = dict[@"post_thumbnail"];
        self.postTitle = dict[@"post_title"];
        self.postType = dict[@"post_type"];
        self.isSticky = [NSNumber numberWithBool:((NSString *)dict[@"sticky"]).boolValue];
        self.terms = dict[@"terms"];
        self.termsNames = dict[@"terms_names"];
        
        self.docType = [dict[@"doc_type"] integerValue];
        self.fileName = dict[@"file_name"];
    }
    return self;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    if (self.postType) postDict[@"post_type"] = self.postType;
    if (self.postStatus) postDict[@"post_status"] = self.postStatus;
    if (self.postTitle) postDict[@"post_title"] = self.postTitle;
    if (self.postAuthor) postDict[@"post_author"] = @(self.postAuthor.integerValue);
    if (self.postExcerpt) postDict[@"post_excerpt"] = self.postExcerpt;
    if (self.postContent) postDict[@"post_content"] = self.postContent;
    if (self.postDate) postDict[@"post_date"] = self.postDate;
    if (self.postDateGMT) postDict[@"post_date_gmt"] = self.postDateGMT;
    if (self.postFormat) postDict[@"post_format"] = self.postFormat;
    if (self.postName) postDict[@"post_name"] = self.postName;
    if (self.postPassword) postDict[@"post_password"] = self.postPassword;
    if (self.commentStatus) postDict[@"comment_status"] = self.commentStatus;
    if (self.pingStatus) postDict[@"ping_status"] = self.pingStatus;
    if (self.isSticky) postDict[@"sticky"] = self.isSticky;
    if (self.postThumbnail) postDict[@"post_thumbnail"] = self.postThumbnail;
    if (self.postParent) postDict[@"post_parent"] = @(self.postParent.integerValue);
    if (self.customFields) postDict[@"custom_fields"] = self.customFields;
    if (self.termsNames) postDict[@"terms_names"] = self.termsNames;

    if (self.postID) postDict[@"post_id"] = self.postID;
    if (self.docType) postDict[@"doc_type"] = @(self.docType);
    if (self.fileName) postDict[@"file_name"] = self.fileName;
    
    return postDict;
}

- (void)dealloc {
    self.commentStatus = nil;
    self.customFields = nil;
    self.guid = nil;
    self.link = nil;
    self.menuOrder = nil;
    self.pingStatus = nil;
    self.postAuthor = nil;
    self.postContent = nil;
    self.postDate = nil;
    self.postDateGMT = nil;
    self.postExcerpt = nil;
    self.postFormat = nil;
    self.postID = nil;
    self.postMIMEType = nil;
    self.postModified = nil;
    self.postModifiedGMT = nil;
    self.postName = nil;
    self.postParent = nil;
    self.postPassword = nil;
    self.postStatus = nil;
    self.postThumbnail = nil;
    self.postTitle = nil;
    self.postType = nil;
    self.isSticky = nil;
    self.terms = nil;
    self.termsNames = nil;

    self.fileName = nil;
    
    [super dealloc];
}

@end
