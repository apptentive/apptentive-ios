//
//  ATMessageCenterBaseViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATSimpleImageViewController.h"
#import "ATAbstractMessage.h"
#import "ATMessageCenterDataSource.h"
#import "ATMessageInputView.h"
#import "ATTextMessage.h"

@protocol ATMessageCenterDismissalDelegate;

@interface ATMessageCenterBaseViewController : UIViewController <ATMessageCenterDataSourceDelegate, ATMessageInputViewDelegate, ATSimpleImageViewControllerDelegate, UIActionSheetDelegate>
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIView *inputContainerView;
@property (assign, nonatomic) NSObject<ATMessageCenterDismissalDelegate> *dismissalDelegate;

- (IBAction)donePressed:(id)sender;
- (IBAction)settingsPressed:(id)sender;
- (IBAction)cameraPressed:(id)sender;

- (ATMessageCenterDataSource *)dataSource;
- (void)showRetryMessageActionSheetWithMessage:(ATAbstractMessage *)message;
- (void)showLongMessageControllerWithMessage:(ATTextMessage *)message;
- (void)relayoutSubviews;
- (void)scrollToBottom;
- (CGRect)currentKeyboardFrameInView;
@end

@protocol ATMessageCenterDismissalDelegate <NSObject>
- (void)messageCenterWillDismiss:(ATMessageCenterBaseViewController *)messageCenter;
@optional
- (void)messageCenterDidDismiss:(ATMessageCenterBaseViewController *)messageCenter;
@end

@protocol ATMessageCenterThemeDelegate <NSObject>
@optional
- (UIView *)titleViewForMessageCenterViewController:(ATMessageCenterBaseViewController *)vc;
- (void)configureSendButton:(UIButton *)sendButton forMessageCenterViewController:(ATMessageCenterBaseViewController *)vc;
- (void)configureAttachmentsButton:(UIButton *)button forMessageCenterViewController:(ATMessageCenterBaseViewController *)vc;
- (UIImage *)backgroundImageForMessageForMessageCenterViewController:(ATMessageCenterBaseViewController *)vc;
@end


