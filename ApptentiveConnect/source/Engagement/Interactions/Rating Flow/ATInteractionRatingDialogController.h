//
//  ATInteractionRatingDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATInteraction.h"


@interface ATInteractionRatingDialogController : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) ATInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ATInteraction *)interaction;
- (void)presentRatingDialogFromViewController:(UIViewController *)viewController;

@end
