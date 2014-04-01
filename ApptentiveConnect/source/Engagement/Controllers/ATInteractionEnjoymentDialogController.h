//
//  ATInteractionEnjoymentDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 2/18/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionEnjoymentDialogController : NSObject

@property (nonatomic, retain, readonly) ATInteraction *interaction;
@property (nonatomic, retain) UIAlertView *enjoymentDialog;
@property (nonatomic, retain) UIViewController *viewController;

- (id)initWithInteraction:(ATInteraction *)interaction;
- (void)showEnjoymentDialogFromViewController:(UIViewController *)viewController;

@end
