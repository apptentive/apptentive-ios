//
//  UIWindow+Apptentive.h
//  Apptentive
//
//  Created by Frank Schmitt on 7/29/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (Apptentive)

+ (instancetype)apptentive_windowWithRootViewController:(UIViewController *)rootViewController;

@end

NS_ASSUME_NONNULL_END
