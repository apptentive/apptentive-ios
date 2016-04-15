//
//  ApptentiveInteractionMessageCenterController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionMessageCenterController : NSObject

- (id)initWithInteraction:(ApptentiveInteraction *)interaction;
- (void)showMessageCenterFromViewController:(UIViewController *)viewController;

@end
