//
//  ApptentiveUnreadMessagesBadgeView.h
//  Apptentive
//
//  Created by Peter Kamb on 6/19/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveUnreadMessagesBadgeView : UIView

+ (instancetype)unreadMessageCountViewBadge;
+ (instancetype)unreadMessageCountViewBadgeWithApptentiveHeart;

@end

NS_ASSUME_NONNULL_END
