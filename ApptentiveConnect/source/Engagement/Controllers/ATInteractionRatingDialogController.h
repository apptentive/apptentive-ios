//
//  ATInteractionRatingDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionRatingDialogController : NSObject
#if TARGET_OS_IPHONE
<UIAlertViewDelegate>
#endif

@property (nonatomic, retain, readonly) ATInteraction *interaction;
@property (nonatomic, retain) UIAlertView *ratingDialog;
@property (nonatomic, retain) UIViewController *viewController;

- (id)initWithInteraction:(ATInteraction *)interaction;
- (void)showRatingDialogFromViewController:(UIViewController *)viewController;

@end
