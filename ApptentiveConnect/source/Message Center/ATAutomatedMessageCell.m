//
//  ATAutomatedMessageCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATAutomatedMessageCell.h"
#import "ATBackend.h"

@implementation ATAutomatedMessageCell
@synthesize dateLabel, showDateLabel, messageText, titleText, grayLineView, containerView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.grayLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_gray_line"]];
	self.containerView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dialog_paper_bg"]];
	//self.containerView.layer.cornerRadius = 10;
	self.containerView.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0].CGColor;
	self.containerView.layer.shadowOffset = CGSizeMake(0, 3);
	self.containerView.layer.shadowRadius = 3;
	self.containerView.layer.shadowOpacity = 1.0;
	self.containerView.layer.masksToBounds = NO;
}

+ (NSString *)reuseIdentifier {
    return @"ATAutomatedMessageCell";
}

- (NSString *)reuseIdentifier {
    return [[self class] reuseIdentifier];
}

- (void)dealloc {
    [dateLabel release];
	[messageText release];
	[titleText release];
	[grayLineView release];
	[containerView release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	
	do { // once
		if (showDateLabel) {
			cellHeight += self.dateLabel.bounds.size.height;
		}
		CGFloat textWidth = width - 60 /* padding between text and edges of cell */;
		CGFloat heightPadding = 8 /* padding at bottom */ +
								2 /* padding above title */ +
								18 /* title text */ +
								3 /* gray line and padding above it */ +
								5 /* padding below gray line */ +
								9 /* padding below main text */;
		CGSize textSize = [self.messageText sizeThatFits:CGSizeMake(textWidth, 2000)];
		cellHeight += MAX(heightPadding + 18 /* one line */, textSize.height + heightPadding);
		
	} while (NO);
	return cellHeight;
}
@end
