//
//  ApptentiveInteractionUpgradeMessageController.h
//  Apptentive
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"


@interface ApptentiveInteractionUpgradeMessageController : ApptentiveInteractionController

// This strong reference makes sure the interaction controller sticks around
// until the view controller is dismissed (required for
// `-dismissAllInteractions:` calls).
@property (strong, nonatomic) ApptentiveInteractionController *interactionController;

@end
