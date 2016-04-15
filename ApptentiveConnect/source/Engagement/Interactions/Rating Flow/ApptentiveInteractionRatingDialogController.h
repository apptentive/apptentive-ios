//
//  ApptentiveInteractionRatingDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionRatingDialogController : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) ApptentiveInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction;
- (void)presentRatingDialogFromViewController:(UIViewController *)viewController;

@end
