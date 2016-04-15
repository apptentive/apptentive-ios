//
//  ApptentiveInteractionUpgradeMessageViewController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ApptentiveInteraction;


@interface ApptentiveInteractionUpgradeMessageViewController : UIViewController

+ (instancetype)interactionUpgradeMessageViewControllerWithInteraction:(ApptentiveInteraction *)interaction;
- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated;

@end
