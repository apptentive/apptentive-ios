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
}
@property (assign, nonatomic) UIStatusBarStyle startingStatusBarStyle;

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) ATDefaultTextView *feedbackView;
@property (nonatomic, strong) UIView *promptContainer;
@property (nonatomic, copy) NSString *promptTitle;
@property (nonatomic, copy) NSString *promptText;
@property (nonatomic, copy) NSString *customPlaceholderText;
@property (nonatomic, assign) BOOL showEmailAddressField;
@property (nonatomic, weak) NSObject<ATMessagePanelDelegate> *delegate;
@property (nonatomic, copy) ATInteraction *interaction;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet ATCustomButton *cancelButton;
@property (nonatomic, strong) IBOutlet ATCustomButton *sendButton;
@property (nonatomic, strong) IBOutlet ATToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIImageView *toolbarShadowImage;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *containerView;


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
