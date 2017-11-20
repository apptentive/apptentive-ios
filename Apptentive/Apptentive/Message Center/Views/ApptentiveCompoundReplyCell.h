//
//  ApptentiveCompoundReplyCell.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterCellProtocols.h"
#import "ApptentiveMessageCenterReplyCell.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveIndexedCollectionView;


@interface ApptentiveCompoundReplyCell : ApptentiveMessageCenterReplyCell <ApptentiveMessageCenterCompoundCell>

@property (weak, nonatomic) IBOutlet ApptentiveIndexedCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end

NS_ASSUME_NONNULL_END
