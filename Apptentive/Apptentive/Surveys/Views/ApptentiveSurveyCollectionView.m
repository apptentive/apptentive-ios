//
//  ApptentiveSurveyCollectionView.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyCollectionView.h"
#import "ApptentiveSurveyCollectionViewLayout.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSurveyCollectionView

- (void)setCollectionHeaderView:(UIView *)collectionHeaderView {
	if (_collectionHeaderView != collectionHeaderView) {
		if (_collectionHeaderView) {
			[_collectionHeaderView removeFromSuperview];
		}

		_collectionHeaderView = collectionHeaderView;
		collectionHeaderView.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:collectionHeaderView];

		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:collectionHeaderView
										 attribute:NSLayoutAttributeWidth
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeWidth
										multiplier:1.0
										  constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionHeaderView
										 attribute:NSLayoutAttributeCenterX
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeCenterX
										multiplier:1.0
										  constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionHeaderView
										 attribute:NSLayoutAttributeTop
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeTop
										multiplier:1.0
										  constant:0.0]
		]];
	}

	[self.collectionViewLayout invalidateLayout];
}

- (void)setCollectionFooterView:(UIView *)collectionFooterView {
	if (_collectionFooterView != collectionFooterView) {
		if (_collectionFooterView) {
			[_collectionFooterView removeFromSuperview];
		}

		_collectionFooterView = collectionFooterView;
		collectionFooterView.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:collectionFooterView];

		self.footerConstraint = [NSLayoutConstraint constraintWithItem:collectionFooterView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];

		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:collectionFooterView
										 attribute:NSLayoutAttributeWidth
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeWidth
										multiplier:1.0
										  constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionFooterView
										 attribute:NSLayoutAttributeCenterX
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeCenterX
										multiplier:1.0
										  constant:0.0],
			self.footerConstraint
		]];
	}

	[self.collectionViewLayout invalidateLayout];
}

@end

NS_ASSUME_NONNULL_END
