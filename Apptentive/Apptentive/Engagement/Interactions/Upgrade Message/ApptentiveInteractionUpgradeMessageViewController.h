//
//  ApptentiveInteractionUpgradeMessageViewController.h
//  Apptentive
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteraction;
@class ApptentiveInteractionController;


@interface ApptentiveInteractionUpgradeMessageViewController : UIViewController

@property (strong, nonatomic) ApptentiveInteraction *upgradeMessageInteraction;

// This strong reference makes sure the interaction controller sticks around
// until the view controller is dismissed (required for
// `-dismissAllInteractions:` calls).
@property (strong, nullable, nonatomic) ApptentiveInteractionController *interactionController;

@end

NS_ASSUME_NONNULL_END
