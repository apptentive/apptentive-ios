//
//  ApptentiveInteractionUpgradeMessageViewController.h
//  Apptentive
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ApptentiveInteraction;
@class ApptentiveInteractionController;


@interface ApptentiveInteractionUpgradeMessageViewController : UIViewController

@property (strong, nonatomic) ApptentiveInteraction *upgradeMessageInteraction;

// This strong reference makes sure the interaction controller sticks around
// until the view controller is dismissed (required for
// `-dismissAllInteractions:` calls).
@property (strong, nonatomic) ApptentiveInteractionController *interactionController;

@end
