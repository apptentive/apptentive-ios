//
//  ATAttachmentCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ATAttachmentCell.h"

@implementation ATAttachmentCell

+ (CGSize)portraitSizeOfScreen:(UIScreen *)screen {
	CGFloat width = CGRectGetWidth(screen.bounds);
	CGFloat height = CGRectGetHeight(screen.bounds);

	if (width > height) {
		CGFloat newWidth = height;
		height = width;
		width = newWidth;
	}

	return CGSizeMake(width, height);
}

+ (NSInteger)countForScreen:(UIScreen *)screen {
	return [self portraitSizeOfScreen:screen].width > 400.0 ? 5 : 4;
}

+ (CGSize)sizeForScreen:(UIScreen *)screen withMargin:(CGSize)margin {
	CGSize size = [self portraitSizeOfScreen:screen];
	CGFloat aspectRatio = size.width / CGRectGetHeight(screen.bounds);
	NSInteger count = [self countForScreen:screen];
	CGFloat totalMargin = margin.width * (count + 1);
	CGFloat imageWidth = (size.width - totalMargin) / count;
	CGFloat imageHeight = imageWidth / aspectRatio;

	return CGSizeMake(imageWidth, imageHeight);
}

+ (CGFloat)heightForScreen:(UIScreen *)screen withMargin:(CGSize)margin {
	CGSize itemSize = [self sizeForScreen:screen withMargin:margin];

	return round(itemSize.height + margin.height * 2.0);
}

- (void)awakeFromNib {
	self.layer.borderColor = [UIColor grayColor].CGColor;
	self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.layer.cornerRadius = 16.0;
}

@end

