//
//  ATMessagePanelViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATCustomButton;
@class ATDefaultTextView;
@class ATToolbar;
@class ATInteraction;

@protocol ATMessagePanelDelegate;

typedef enum {
	ATMessagePanelDidSendMessage,
	ATMessagePanelDidCancel,
	ATMessagePanelWasDismissed
} ATMessagePanelDismissAction;

@interface ATMessagePanelViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate> {
	UIViewController *presentingViewController;

	UIStatusBarStyle startingStatusBarStyle;
	UIViewTintAdjustmentMode startingTintAdjustmentMode;
	BOOL showEmailAddressField;
	UIWindow *originalPresentingWindow;
	NSObject<ATMessagePanelDelegate> *delegate;
	
	UIAlertView *noEmailAddressAlert;
	UIAlertView *invalidEmailAddressAlert;
	UIAlertView *emailRequiredAlert;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ATCustomButton *cancelButton;
@property (nonatomic, retain) IBOutlet ATCustomButton *sendButton;
@property (nonatomic, retain) IBOutlet ATToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIImageView *toolbarShadowImage;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *containerView;
@property (nonatomic, retain) UITextField *emailField;
@property (nonatomic, retain) ATDefaultTextView *feedbackView;
@property (nonatomic, retain) UIView *promptContainer;
@property (nonatomic, copy) NSString *promptTitle;
@property (nonatomic, copy) NSString *promptText;
@property (nonatomic, copy) NSString *customPlaceholderText;
@property (nonatomic, assign) BOOL showEmailAddressField;
@property (nonatomic, assign) NSObject<ATMessagePanelDelegate> *delegate;
@property (nonatomic, copy) ATInteraction *interaction;

- (id)initWithDelegate:(NSObject<ATMessagePanelDelegate> *)delegate;
- (IBAction)cancelPressed:(id)sender;
- (IBAction)sendPressed:(id)sender;

- (void)presentFromViewController:(UIViewController *)presentingViewController animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action;
- (void)dismiss:(BOOL)animated;
@end

@protocol ATMessagePanelDelegate <NSObject>
- (void)messagePanelDidCancel:(ATMessagePanelViewController *)messagePanel;
- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didSendMessage:(NSString *)message withEmailAddress:(NSString *)emailAddress;
- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didDismissWithAction:(ATMessagePanelDismissAction)action;
@end
