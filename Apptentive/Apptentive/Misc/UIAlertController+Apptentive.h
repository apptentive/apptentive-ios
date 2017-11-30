//
//  UIAlertController+Apptentive.h
//  Apptentive
//
//  Created by Alex Lementuev on 8/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIAlertController (Apptentive)

- (void)apptentive_presentAnimated:(BOOL)animated completion:(void (^__nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
