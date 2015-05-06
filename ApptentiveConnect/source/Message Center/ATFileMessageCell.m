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

@interface ATFileMessageCell ()

@property (assign, nonatomic) CGSize cachedThumbnailSize;
@property (strong, nonatomic) ATFileMessage *fileMessage;
@property (strong, nonatomic) UIImage *currentImage;

@end

@implementation ATFileMessageCell

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
	if (_showDateLabel != show) {
		_showDateLabel = show;
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if (self.showDateLabel == NO) {
		self.dateLabel.hidden = YES;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height;
		chatBubbleRect.origin.y = 0;
		self.chatBubbleContainer.frame = chatBubbleRect;
	} else {
		self.dateLabel.hidden = NO;
		CGRect dateLabelRect = self.dateLabel.frame;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height - dateLabelRect.size.height;
		chatBubbleRect.origin.y = dateLabelRect.size.height;
		self.chatBubbleContainer.frame = chatBubbleRect;
	}
	self.imageContainer.layer.borderColor = [UIColor grayColor].CGColor;
	self.imageContainer.layer.borderWidth = 1;
	self.imageContainer.layer.cornerRadius = 2;
	self.imageContainer.backgroundColor = [UIColor grayColor];
	self.imageContainer.clipsToBounds = YES;
	self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
}

- (void)setCurrentImage:(UIImage *)image {
	if (_currentImage != image) {
		_currentImage = image;
		if (_currentImage != nil) {
			self.imageContainer.layer.contents = (id)self.currentImage.CGImage;
			self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
		}
	}
	if (_currentImage == nil) {
		_currentImage = [ATBackend imageNamed:@"at_mc_file_default"];
		self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
		self.imageContainer.layer.contents = (id)self.currentImage.CGImage;
	}
}

- (void)configureWithFileMessage:(ATFileMessage *)message {
	if (message != self.fileMessage) {
		self.currentImage = nil;
		self.fileMessage = message;
		
		UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
		CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(320, 320));
		self.cachedThumbnailSize = thumbnailSize;
		CGFloat scale = [[UIScreen mainScreen] scale];
		thumbnailSize.width *= scale;
		thumbnailSize.height *= scale;
		
		UIImage *thumbnail = [message.fileAttachment thumbnailOfSize:thumbnailSize];
		if (thumbnail) {
			self.currentImage = thumbnail;
			self.imageContainer.layer.contents = (id)self.currentImage.CGImage;
		} else {
			self.currentImage = nil;
			[message.fileAttachment createThumbnailOfSize:thumbnailSize completion:^{
				UIImage *image = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
				[self setCurrentImage:image];
			}];
		}
		
		[self setNeedsLayout];
	}
}

+ (NSString *)reuseIdentifier {
    return @"ATFileMessageCell";
}

- (NSString *)reuseIdentifier {
    return [[self class] reuseIdentifier];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	if (self.showDateLabel) {
		cellHeight += self.dateLabel.bounds.size.height;
	}
	
	CGSize thumbSize = self.cachedThumbnailSize;
	if (CGSizeEqualToSize(CGSizeZero, thumbSize)) {
		thumbSize = CGSizeMake(320, 320);
	}
	thumbSize.width = MAX(thumbSize.width, 1);
	CGFloat thumbRatio = thumbSize.height/thumbSize.width;
	
	UIEdgeInsets chatBubbleInsets = [ATUtilities edgeInsetsOfView:self.chatBubbleContainer];
	UIEdgeInsets imageInsets = [ATUtilities edgeInsetsOfView:self.imageContainer];
	
	CGFloat imageContainerWidth = width - (chatBubbleInsets.left + chatBubbleInsets.right + imageInsets.left + imageInsets.right);
	CGFloat scaledHeight = ceil(imageContainerWidth * thumbRatio);
	cellHeight += MAX(150, scaledHeight);
	cellHeight += imageInsets.top + imageInsets.bottom;
	return cellHeight;
}

@end
