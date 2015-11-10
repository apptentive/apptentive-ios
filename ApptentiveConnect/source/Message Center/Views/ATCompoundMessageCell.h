//
//  ATCompoundMessageCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterMessageCell.h"

@class ATIndexedCollectionView;

@interface ATCompoundMessageCell : ATMessageCenterMessageCell

@property (weak, nonatomic) IBOutlet ATIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
