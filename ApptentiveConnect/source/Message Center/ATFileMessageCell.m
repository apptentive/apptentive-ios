//
//  ATFileMessageCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATFileMessageCell.h"

@implementation ATFileMessageCell
@synthesize dateLabel, userIcon, imageContainer, showDateLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setShowDateLabel:(BOOL)show {
	if (showDateLabel != show) {
		showDateLabel = show;
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGFloat heightPadding = 19;
	if (showDateLabel == NO) {
		self.dateLabel.hidden = YES;
		CGRect imageRect = self.imageContainer.frame;
		imageRect.size.height = self.bounds.size.height - heightPadding;
		imageRect.origin.y = 0;
		self.imageContainer.frame = imageRect;
	} else {
		self.dateLabel.hidden = NO;
		CGRect dateLabelRect = self.dateLabel.frame;
		CGRect imageRect = self.imageContainer.frame;
		imageRect.size.height = self.bounds.size.height - dateLabelRect.size.height - 9;
		imageRect.origin.y = dateLabelRect.size.height;
		self.imageContainer.frame = imageRect;
	}
	self.imageContainer.layer.cornerRadius = 8;
	self.imageContainer.backgroundColor = [UIColor blackColor];
	self.imageContainer.clipsToBounds = YES;
	self.imageContainer.layer.contentsGravity = kCAGravityResizeAspectFill;
}

- (void)configureWithFileMessage:(ATFileMessage *)message {
	if (message != fileMessage) {
		[fileMessage release], fileMessage = nil;
		[currentImage release], currentImage = nil;
		fileMessage = [message retain];
		currentImage = [[UIImage imageWithContentsOfFile:[fileMessage.fileAttachment fullLocalPath]] retain];
		self.imageContainer.layer.contents = (id)currentImage.CGImage;
		[self setNeedsLayout];
	}
}

- (void)dealloc {
    [dateLabel release], dateLabel = nil;
    [userIcon release], userIcon = nil;
	[imageContainer release];
	[fileMessage release], fileMessage = nil;
	[currentImage release], currentImage = nil;
    [super dealloc];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	
	do { // once
		if (showDateLabel) {
			cellHeight += self.dateLabel.bounds.size.height;
		}
		
		CGSize imageSize = currentImage.size;
		CGFloat widthRatio = self.imageContainer.bounds.size.width/imageSize.width;
		CGSize scaledImageSize = CGSizeMake(self.imageContainer.bounds.size.width, imageSize.height * widthRatio);
		
		CGFloat imageHeight = scaledImageSize.height;
		CGFloat heightPadding = 19;
		
		cellHeight += MAX(60, imageHeight + heightPadding);
		
		cellHeight = MIN(150, cellHeight);
		
	} while (NO);
	return cellHeight;
}
@end
