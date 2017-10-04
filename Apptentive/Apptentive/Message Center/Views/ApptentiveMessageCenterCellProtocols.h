//
//  ApptentiveMessageCenterCellProtocols.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

@class ApptentiveIndexedCollectionView;

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveMessageCenterCell <NSObject>

@property (weak, nonatomic) UITextView *messageLabel;

@end

@protocol ApptentiveMessageCenterCompoundCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) ApptentiveIndexedCollectionView *collectionView;
@property (weak, nonatomic) NSLayoutConstraint *collectionViewHeightConstraint;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end

NS_ASSUME_NONNULL_END
