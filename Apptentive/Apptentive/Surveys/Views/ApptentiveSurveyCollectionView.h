//
//  ApptentiveSurveyCollectionView.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyCollectionView : UICollectionView

@property (strong, nonatomic) UIView *collectionHeaderView;
@property (strong, nonatomic) UIView *collectionFooterView;
@property (strong, nonatomic) NSLayoutConstraint *footerConstraint;

@end

@protocol ApptentiveCollectionViewDataSource <UICollectionViewDataSource>

- (BOOL)sectionAtIndexIsValid:(NSInteger)index;
@property (readonly, nonatomic) UIColor *validColor;
@property (readonly, nonatomic) UIColor *invalidColor;
@property (readonly, nonatomic) UIColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END
