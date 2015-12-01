//
//  ATInteractionTextModalController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATInteraction.h"


@interface ATInteractionTextModalController : NSObject <UIAlertViewDelegate>

typedef void (^alertActionHandler)(UIAlertAction *);

@property (nonatomic, strong) ATInteraction *interaction;
@property (nonatomic, strong) UIViewController *viewController;

// Used in iOS 8 and later
@property (nonatomic, strong) UIAlertController *alertController;

// Used in iOS 7 and previous
@property (nonatomic, strong) UIAlertView *alertView;

- (instancetype)initWithInteraction:(ATInteraction *)interaction;
- (void)presentTextModalAlertFromViewController:(UIViewController *)viewController;

@end
