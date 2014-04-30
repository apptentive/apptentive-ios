//
//  ATInteractionSurveyController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionSurveyController : NSObject

@property (nonatomic, retain, readonly) ATInteraction *interaction;
@property (nonatomic, retain) UIViewController *viewController;

- (id)initWithInteraction:(ATInteraction *)interaction;
- (void)showSurveyFromViewController:(UIViewController *)viewController;

@end
