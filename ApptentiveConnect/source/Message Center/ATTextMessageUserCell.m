//
//  ATTextMessageUserCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/9/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessageUserCell.h"

@implementation ATTextMessageUserCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
	[_userIcon release];
	[_messageBubbleImage release];
	[_messageText release];
	[super dealloc];
}


- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat textWidth = width - 101;
	CGFloat heightPadding = 19;
	CGSize textSize = [self.messageText.text sizeWithFont:self.messageText.font constrainedToSize:CGSizeMake(textWidth, 2000) lineBreakMode:self.messageText.lineBreakMode];
	return MAX(60, textSize.height + heightPadding);
}
@end
