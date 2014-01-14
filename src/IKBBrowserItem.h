//
//  IKBBrowserItem.h
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface IKBBrowserItem : NSObject

@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSString *imageID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *fileName;

+ (IKBBrowserItem *)browserItem;

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*)imageTitle;

@end
