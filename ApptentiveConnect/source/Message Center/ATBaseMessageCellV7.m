//
//  ATBaseMessageCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATBaseMessageCellV7.h"

NSString *const ATMessageCollectionDidScroll = @"ATMessageCollectionDidScroll";
NSString *const ATMessageCollectionTopOffsetKey = @"topOffset";

@implementation ATBaseMessageCellV7

- (void)didScroll:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	NSNumber *offset = userInfo[ATMessageCollectionTopOffsetKey];
	if (offset) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
		CGFloat topOffset = CGFLOAT_IS_DOUBLE ? [offset doubleValue] : [offset floatValue];
#pragma clang diagnostic pop
		UIView *collectionView = self;
		while ((collectionView = [collectionView superview])) {
			if ([collectionView isKindOfClass:[UICollectionView class]]) {
				break;
			}
		}
		if (collectionView && [collectionView isKindOfClass:[UICollectionView class]]) {
			[self collection:(UICollectionView *)collectionView didScroll:topOffset];
		}
	}
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:ATMessageCollectionDidScroll object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)collection:(UICollectionView *)collectionView didScroll:(CGFloat)topOffset {
}
@end
