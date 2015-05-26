//
//  ATInteractionMessageCenterController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATMessageCenterInteraction;

@interface ATInteractionMessageCenterController : NSObject

@property (nonatomic, strong, readonly) ATMessageCenterInteraction *interaction;
@property (nonatomic, strong) UIViewController *viewController;

- (id)initWithInteraction:(ATMessageCenterInteraction *)interaction;
- (void)showMessageCenterFromViewController:(UIViewController *)viewController;

@end
