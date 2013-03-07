//
//  ATFileMessageCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATFileMessageCell.h"

#import "ATBackend.h"
#import "ATUtilities.h"

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

- (void)setCurrentImage:(UIImage *)image {
	if (currentImage != image) {
		[currentImage release], currentImage = nil;
		currentImage = [image retain];
		if (currentImage != nil) {
			self.imageContainer.layer.contents = (id)currentImage.CGImage;
		}
	}
	if (currentImage == nil) {
		currentImage = [[ATBackend imageNamed:@"at_mc_file_default"] retain];
		self.imageContainer.layer.contents = (id)currentImage.CGImage;
	}
}

- (void)configureWithFileMessage:(ATFileMessage *)message {
	if (message != fileMessage) {
		[fileMessage release], fileMessage = nil;
		[currentImage release], currentImage = nil;
		fileMessage = [message retain];
		
		UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
		CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(320, 320));
		UIImage *thumbnail = [message.fileAttachment thumbnailOfSize:thumbnailSize];
		if (thumbnail) {
			[currentImage release], currentImage = nil;
			currentImage = [thumbnail retain];
			self.imageContainer.layer.contents = (id)currentImage.CGImage;
		} else {
			[self setCurrentImage:nil];
			[message.fileAttachment createThumbnailOfSize:thumbnailSize completion:^{
				UIImage *image = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
				[self setCurrentImage:image];
			}];
		}
		
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
	return 320;
	
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
