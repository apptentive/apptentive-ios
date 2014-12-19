//
//  ATInteractionUIAlertController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionUIAlertController : UIAlertController

typedef void (^alertActionHandler)(UIAlertAction *);

@property (nonatomic, retain) ATInteraction *interaction;
@property (nonatomic, retain) UIViewController *viewController;

+ (instancetype)alertControllerWithInteraction:(ATInteraction *)interaction;

- (void)presentAlertControllerFromViewController:(UIViewController *)viewController;

- (UIAlertAction *)alertActionWithConfiguration:(NSDictionary *)configuration;

- (alertActionHandler)createButtonHandlerBlockDismiss;
- (alertActionHandler)createButtonHandlerBlockWithInvocations:(NSArray *)invocations;

@end
