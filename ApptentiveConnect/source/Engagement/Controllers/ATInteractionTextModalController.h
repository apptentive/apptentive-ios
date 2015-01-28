//
//  ATInteractionTextModalController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionTextModalController : NSObject <UIAlertViewDelegate>

typedef void (^alertActionHandler)(UIAlertAction *);

@property (nonatomic, retain) ATInteraction *interaction;
@property (nonatomic, retain) UIViewController *viewController;

@property (nonatomic, retain) UIAlertController *alertController;
@property (nonatomic, retain) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ATInteraction *)interaction;
- (void)presentTextModalAlertFromViewController:(UIViewController *)viewController;

@end
