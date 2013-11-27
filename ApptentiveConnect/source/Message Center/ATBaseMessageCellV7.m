//
//  ATBaseMessageCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATBaseMessageCellV7.h"

@implementation ATBaseMessageCellV7 {
	NSObject<ATMessageCellV7CachingDelegate> *cachingDelegate;
	NSIndexPath *currentIndexPath;
}

- (void)setCachingDelegate:(NSObject<ATMessageCellV7CachingDelegate> *)aCachingDelegate andIndexPath:(NSIndexPath *)indexPath {
	if (cachingDelegate != aCachingDelegate) {
		cachingDelegate = aCachingDelegate;
	}
	if (indexPath != currentIndexPath) {
		[currentIndexPath release], currentIndexPath = nil;
		indexPath = [indexPath copy];
	}
}

- (void)prepareForReuse {
	[super prepareForReuse];
	if (cachingDelegate) {
		[cachingDelegate messageCell:self preparingForReuseAtPath:currentIndexPath];
	}
}

- (void)dealloc {
	[currentIndexPath release], currentIndexPath = nil;
	cachingDelegate = nil;
	[super dealloc];
}
@end
