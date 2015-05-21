//
//  ATMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATMessageCenterDismissalDelegate;

@interface ATMessageCenterViewController : UITableViewController

@property (nonatomic, weak) NSObject<ATMessageCenterDismissalDelegate> *dismissalDelegate;

@end

@protocol ATMessageCenterDismissalDelegate <NSObject>
- (void)messageCenterWillDismiss:(ATMessageCenterViewController *)messageCenter;
@optional
- (void)messageCenterDidDismiss:(ATMessageCenterViewController *)messageCenter;
@end

