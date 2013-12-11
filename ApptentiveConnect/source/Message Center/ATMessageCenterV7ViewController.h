//
//  ATMessageCenterV7ViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterBaseViewController.h"

#import "ATBaseMessageCellV7.h"

@interface ATMessageCenterV7ViewController : ATMessageCenterBaseViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
@property (retain, nonatomic) IBOutlet UICollectionView *collectionView;
@property (retain, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (retain, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end
