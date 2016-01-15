//
//  ATInteractionSurveyController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ATInteraction;


@interface ATInteractionSurveyController : NSObject

@property (readonly, strong, nonatomic) ATInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

- (id)initWithInteraction:(ATInteraction *)interaction;
- (void)showSurveyFromViewController:(UIViewController *)viewController;

@end
