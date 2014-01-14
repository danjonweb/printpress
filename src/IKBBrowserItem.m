//
//  IKBBrowserItem.m
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import "IKBBrowserItem.h"


@implementation IKBBrowserItem

+ (IKBBrowserItem *)browserItem {
    return [[IKBBrowserItem alloc] init];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    IKBBrowserItem *item = (IKBBrowserItem *)other;
    return [self.imageID isEqualToString:item.imageID];
}

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *) imageUID {
    return self.imageID;
}

- (NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation {
	return self.image;
}

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*)imageTitle {
    return self.title;
}

@end
