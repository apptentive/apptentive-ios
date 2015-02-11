//
//  ATFileMessageUserCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATFileMessageUserCellV7.h"

#import "ATBackend.h"
#import "ATMessageSender.h"
#import "ATUtilities.h"

#define kMinimumIconConstraint 4

@implementation ATFileMessageUserCellV7 {
	UIImage *currentImage;
}

- (void)setup {
	self.userIconView.image = [ATBackend imageNamed:@"at_mc_user_icon_default"];
	self.userIconView.imageURL = [NSURL URLWithString:self.message.sender.profilePhotoURL];
	
	self.userIconView.layer.cornerRadius = self.userIconView.bounds.size.width*0.5;
	self.userIconView.layer.masksToBounds = YES;
	
	self.imageContainerView.layer.cornerRadius = 4;
	self.imageContainerView.clipsToBounds = YES;
	
	self.imageShadowView.clipsToBounds = NO;
	self.imageShadowView.userInteractionEnabled = NO;
	self.imageShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.imageShadowView.layer.shadowRadius = 3;
	self.imageShadowView.layer.shadowOpacity = 0.22;
	self.imageShadowView.layer.shadowOffset = CGSizeMake(0, 0);
	
	self.arrowView.direction = ATMessageBubbleArrowDirectionRight;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setup];
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.userIconOffsetConstraint.constant = kMinimumIconConstraint;
	[self setup];
}

- (void)dealloc {
	[_userIconView release];
	[currentImage release];
	[_imageContainerView release];
	[_imageWidthConstraint release];
	[_imageHeightConstraint release];
	[_imageShadowView release];
	[super dealloc];
}

- (void)prepareForReuse {
	[super prepareForReuse];
	self.message = nil;
	
	self.imageWidthConstraint.constant = 0;
	self.imageHeightConstraint.constant = 0;
	self.userIconOffsetConstraint.constant = kMinimumIconConstraint;
}

- (void)setMessage:(ATFileMessage *)message {
	if (_message != message) {
		[_message release], _message = nil;
		_message = [message retain];
		if (_message == nil) {
			[self setCurrentImage:nil];
			return;
		}
		UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
		//TODO: Sizing on iPad
		CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(260, 260));
		CGFloat scale = [[UIScreen mainScreen] scale];
		CGSize scaledThumbnailSize = thumbnailSize;
		scaledThumbnailSize.width *= scale;
		scaledThumbnailSize.height *= scale;
		
		UIImage *thumbnail = [message.fileAttachment thumbnailOfSize:scaledThumbnailSize];
		if (thumbnail) {
			[currentImage release], currentImage = nil;
			currentImage = [thumbnail retain];
			self.imageWidthConstraint.constant = thumbnailSize.width;
			self.imageHeightConstraint.constant = thumbnailSize.height;
			self.imageContainerView.layer.contents = (id)currentImage.CGImage;
		} else {
			[self setCurrentImage:nil];
			[message.fileAttachment createThumbnailOfSize:scaledThumbnailSize completion:^{
				UIImage *image = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
				[self setCurrentImage:image];
			}];
		}
		
		[self setup];
	}
}

- (void)setCurrentImage:(UIImage *)image {
	if (currentImage != image) {
		[currentImage release], currentImage = nil;
		currentImage = [image retain];
		if (currentImage != nil) {
			CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(currentImage.size, CGSizeMake(260, 260));
			self.imageWidthConstraint.constant = thumbnailSize.width;
			self.imageHeightConstraint.constant = thumbnailSize.height;
			self.imageContainerView.layer.contents = (id)currentImage.CGImage;
			self.imageContainerView.layer.contentsGravity = kCAGravityResizeAspect;
		}
	}
	if (currentImage == nil) {
		currentImage = [[ATBackend imageNamed:@"at_mc_file_default"] retain];
		self.imageContainerView.layer.contentsGravity = kCAGravityResizeAspect;
		self.imageContainerView.layer.contents = (id)currentImage.CGImage;
	}
}

- (void)collection:(UICollectionView *)collectionView didScroll:(CGFloat)topOffset {
	CGRect iconInset = [collectionView convertRect:self.frame fromView:self.superview];
	iconInset.origin.y += topOffset - 1;
	iconInset.origin.y += CGRectGetMaxY(self.dateLabel.bounds);
	
	CGFloat minOffset = kMinimumIconConstraint;
	CGFloat minBottomOffset = 16;
	CGFloat maxOffset = CGRectGetHeight(self.bounds) - CGRectGetHeight(self.userIconView.bounds) - minBottomOffset - CGRectGetMinY(self.userIconOffsetView.frame);
	CGFloat iconInsetY = -CGRectGetMinY(iconInset);
	CGFloat newValue = MAX(minOffset, MIN(maxOffset, iconInsetY));
	self.userIconOffsetConstraint.constant = newValue;
}
@end
