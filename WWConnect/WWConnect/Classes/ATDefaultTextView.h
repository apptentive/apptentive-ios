//
//  ATDefaultTextView.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATDefaultTextView : UITextView {
@private
    UIColor *originalTextColor;
    UIColor *placeholderTextColor;
}
@property (nonatomic, retain) NSString *placeholder;
- (BOOL)isDefault;
@end
