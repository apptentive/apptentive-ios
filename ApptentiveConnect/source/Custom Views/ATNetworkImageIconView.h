//
//  ATNetworkImageIconView.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 6/1/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATNetworkImageView.h"

typedef NS_ENUM(NSInteger, ATImageViewMaskType) {
	ATImageViewMaskTypeNone = 0,
	ATImageViewMaskTypeRound,
	ATImageViewMaskTypeAppIcon
};

@interface ATNetworkImageIconView : ATNetworkImageView

@property (assign, nonatomic) ATImageViewMaskType maskType;

@end
