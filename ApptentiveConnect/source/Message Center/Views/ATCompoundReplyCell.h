//
//  ATCompoundReplyCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterReplyCell.h"
#import "ATMessageCenterCellProtocols.h"

@class ATIndexedCollectionView;

@interface ATCompoundReplyCell : ATMessageCenterReplyCell <ATMessageCenterCompoundCell>

@property (weak, nonatomic) IBOutlet ATIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
