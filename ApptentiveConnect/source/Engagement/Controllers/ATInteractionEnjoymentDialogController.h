//
//  ATInteractionEnjoymentDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 2/18/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionEnjoymentDialogController : NSObject

@property (nonatomic, strong, readonly) ATInteraction *interaction;
@property (nonatomic, strong) UIAlertView *enjoymentDialog;
@property (nonatomic, strong) UIViewController *viewController;

- (id)initWithInteraction:(ATInteraction *)interaction;
- (void)showEnjoymentDialogFromViewController:(UIViewController *)viewController;

@end
