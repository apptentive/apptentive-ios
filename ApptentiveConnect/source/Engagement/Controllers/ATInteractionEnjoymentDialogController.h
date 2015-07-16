//
//  ATInteractionEnjoymentDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionEnjoymentDialogController : NSObject <UIAlertViewDelegate>

<<<<<<< HEAD
@property (nonatomic, strong, readonly) ATInteraction *interaction;
@property (nonatomic, strong) UIAlertView *enjoymentDialog;
@property (nonatomic, strong) UIViewController *viewController;
=======
@property (nonatomic, retain) ATInteraction *interaction;
@property (nonatomic, retain) UIViewController *viewController;
>>>>>>> master

@property (nonatomic, retain) UIAlertController *alertController;
@property (nonatomic, retain) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ATInteraction *)interaction;
- (void)presentEnjoymentDialogFromViewController:(UIViewController *)viewController;

@end
