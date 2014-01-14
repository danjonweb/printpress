//
//  LSPopUpButton.h
//  Blog Creature
//
//  Created by Daniel Weber on 8/8/12.
//
//

#import <Cocoa/Cocoa.h>

@interface LSColorPopUpButton : NSPopUpButton <NSWindowDelegate> {
    BOOL mouseDownInColorSection;
    
    NSMutableDictionary *hexToNameDict;
    NSMutableDictionary *nameToHexDict;
    NSMutableDictionary *nameToRGBDict;
}

- (void)selectRGBColorString:(NSString *)string;
- (void)clearColor;

@property (nonatomic, copy) NSString *rgbString;
@property (nonatomic, copy) NSString *hexString;

@end
