//
//  NSString+UUID.m
//  Blogmator
//
//  Created by Dan Weber on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString *)uniqueString {
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	NSString *uString = (NSString *)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);
	return [uString autorelease];
}

@end
