//
//  ImageWithPathView.h
//  Blog Creature
//
//  Created by Daniel Weber on 7/25/12.
//
//

#import <Cocoa/Cocoa.h>

extern NSString *UploadImageDidChangeNotification;

@interface ImageWithPathView : NSImageView
{
}

@property (nonatomic, copy) NSString *filePath;

@end