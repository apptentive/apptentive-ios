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

@implementation ATFileMessageUserCellV7 {
	UIImage *currentImage;
}

- (void)setup {
	self.userIconView.image = [ATBackend imageNamed:@"at_mc_user_icon"];
	self.userIconView.imageURL = [NSURL URLWithString:self.message.sender.profilePhotoURL];
	self.userIconView.layer.cornerRadius = self.userIconView.bounds.size.width*0.5;
	self.userIconView.layer.masksToBounds = YES;
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
	[self setup];
}

- (void)dealloc {
	[_userIconView release];
	[currentImage release];
	[_imageContainerView release];
	[super dealloc];
}

- (void)setMessage:(ATFileMessage *)message {
	if (_message != message) {
		[_message release], _message = nil;
		_message = [message retain];
		
		UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
		CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(320, 320));
		CGFloat scale = [[UIScreen mainScreen] scale];
		thumbnailSize.width *= scale;
		thumbnailSize.height *= scale;
		
		UIImage *thumbnail = [message.fileAttachment thumbnailOfSize:thumbnailSize];
		if (thumbnail) {
			[currentImage release], currentImage = nil;
			currentImage = [thumbnail retain];
			self.imageContainerView.layer.contents = (id)currentImage.CGImage;
		} else {
			[self setCurrentImage:nil];
			[message.fileAttachment createThumbnailOfSize:thumbnailSize completion:^{
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
@end
