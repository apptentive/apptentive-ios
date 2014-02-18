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

@property (nonatomic, retain) ATInteraction *enjoymentDialogInteraction;

- (id)initWithInteraction:(ATInteraction *)interaction;

- (void)showRatingFlowFromViewController:(UIViewController *)viewController;

@end
