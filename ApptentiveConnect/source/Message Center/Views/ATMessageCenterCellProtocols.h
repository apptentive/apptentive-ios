//
//  ATMessageCenterCellProtocols.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

@class ATIndexedCollectionView;

@protocol ATMessageCenterCell <NSObject>

@property (weak, nonatomic) UITextView *messageLabel;

@end

@protocol ATMessageCenterCompoundCell <ATMessageCenterCell>

@property (weak, nonatomic) ATIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
