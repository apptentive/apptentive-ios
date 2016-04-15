//
//  ApptentiveInteractionSurveyController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ApptentiveInteraction;


@interface ApptentiveInteractionSurveyController : NSObject

@property (readonly, strong, nonatomic) ApptentiveInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

- (id)initWithInteraction:(ApptentiveInteraction *)interaction;
- (void)showSurveyFromViewController:(UIViewController *)viewController;

@end
