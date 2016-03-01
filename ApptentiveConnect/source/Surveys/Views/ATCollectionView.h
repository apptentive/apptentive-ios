//
//  ATCollectionView.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATCollectionView : UICollectionView

@property (strong, nonatomic) UIView *collectionHeaderView;
@property (strong, nonatomic) UIView *collectionFooterView;

@end

@protocol ATCollectionViewDataSource <UICollectionViewDataSource>

- (BOOL)sectionAtIndexIsValid:(NSInteger)index;

@end
