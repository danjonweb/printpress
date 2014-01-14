//
//  LSTextFieldCell.h
//  Printpress
//
//  Created by Daniel Weber on 12/2/12.
//
//

#import <Cocoa/Cocoa.h>

@interface LSTextFieldCell : NSTextFieldCell

@property (nonatomic, assign) BOOL isGroupItem;
@property (nonatomic, assign) BOOL isIndented;
@property (nonatomic, copy) NSString *previousTitle;

@end
