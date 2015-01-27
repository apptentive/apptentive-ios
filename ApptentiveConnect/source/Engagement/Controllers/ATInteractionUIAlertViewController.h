//
//  ATInteractionUIAlertViewController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/26/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionUIAlertViewController : NSObject <UIAlertViewDelegate>

@property (nonatomic, retain) ATInteraction *interaction;
@property (nonatomic, retain) UIAlertView *alertView;

- (void)presentAlertViewWithInteraction:(ATInteraction *)interaction;

@end
