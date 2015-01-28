//
//  ATInteractionTextModalController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATInteractionTextModalController : NSObject

- (instancetype)initWithInteraction:(ATInteraction *)interaction;
- (void)presentTextModalAlertFromViewController:(UIViewController *)viewController;

@end
