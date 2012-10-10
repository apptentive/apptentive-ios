//
//  ATTextMessageUserCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/9/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"

@interface ATTextMessageUserCell : UITableViewCell
@property (retain, nonatomic) IBOutlet UIImageView *userIcon;
@property (retain, nonatomic) IBOutlet UIImageView *messageBubbleImage;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *messageText;

- (CGFloat)cellHeightForWidth:(CGFloat)width;
@end
