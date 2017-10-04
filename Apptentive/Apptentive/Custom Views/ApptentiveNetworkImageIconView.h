//
//  ApptentiveNetworkImageIconView.h
//  Apptentive
//
//  Created by Frank Schmitt on 6/1/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkImageView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATImageViewMaskType) {
	ATImageViewMaskTypeNone = 0,
	ATImageViewMaskTypeRound,
	ATImageViewMaskTypeAppIcon
};


@interface ApptentiveNetworkImageIconView : ApptentiveNetworkImageView

@property (assign, nonatomic) ATImageViewMaskType maskType;

@end

NS_ASSUME_NONNULL_END
