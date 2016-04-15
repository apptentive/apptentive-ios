//
//  ApptentiveInteractionTextModalController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionTextModalController : NSObject <UIAlertViewDelegate>

typedef void (^alertActionHandler)(UIAlertAction *);

@property (strong, nonatomic) ApptentiveInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

// Used in iOS 8 and later
@property (strong, nonatomic) UIAlertController *alertController;

// Used in iOS 7 and previous
@property (strong, nonatomic) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction;
- (void)presentTextModalAlertFromViewController:(UIViewController *)viewController;

@end
