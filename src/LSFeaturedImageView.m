//
//  LSFeaturedImageView.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/2/12.
//
//

#import "LSFeaturedImageView.h"

@implementation LSFeaturedImageView

@synthesize imageID;

- (void)dealloc {
    [imageID release];
    [super dealloc];
}

@end
