//
//  ApptentiveInteractionAppStoreController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
@class ApptentiveInteraction;


@interface ApptentiveInteractionAppStoreController : NSObject <SKStoreProductViewControllerDelegate, UIAlertViewDelegate>

@property (readonly, strong, nonatomic) ApptentiveInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

- (id)initWithInteraction:(ApptentiveInteraction *)interaction;
- (void)openAppStoreFromViewController:(UIViewController *)viewController;

@end
