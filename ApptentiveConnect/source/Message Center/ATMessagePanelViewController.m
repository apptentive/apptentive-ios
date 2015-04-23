//
//  ATMessagePanelViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATMessagePanelViewController.h"

#import "ATConnect_Private.h"
#import "ATContactStorage.h"
#import "ATCustomButton.h"
#import "ATCustomView.h"
#import "ATToolbar.h"
#import "ATDefaultTextView.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATHUDView.h"
#import "ATLabel.h"
#import "ATMessageCenterMetrics.h"
#import "ATUtilities.h"
#import "ATShadowView.h"
#import "ATInteraction.h"

#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

enum {
	kMessagePanelContainerViewTag = 1009,
	kATEmailAlertTextFieldTag = 1010,
	kMessagePanelGradientLayerTag = 1011,
};

@interface ATMessagePanelViewController ()

@end

@interface ATMessagePanelViewController (Private)
- (void)setupContainerView;
- (void)setupScrollView;
- (void)teardown;
- (BOOL)shouldReturn:(UIView *)view;
- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen;
- (UIWindow *)windowForViewController:(UIViewController *)viewController;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
- (void)statusBarChanged:(NSNotification *)notification;
- (void)keyboardWasShown:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)feedbackChanged:(NSNotification *)notification;
- (void)hide:(BOOL)animated;
- (void)finishHide;
- (void)finishUnhide;
- (void)sendMessageAndDismiss;
- (void)updateSendButtonState;
@end

@interface ATMessagePanelViewController (Positioning)
- (BOOL)isIPhoneAppInIPad;
- (CGRect)onscreenRectOfView;
- (CGPoint)offscreenPositionOfView;
- (void)positionInWindow;
@end

@implementation ATMessagePanelViewController {
	CGRect lastKeyboardRect;
}
@synthesize window;
@synthesize cancelButton;
@synthesize sendButton;
@synthesize toolbar;
@synthesize scrollView;
@synthesize containerView;
@synthesize emailField;
@synthesize feedbackView;
@synthesize promptContainer;
@synthesize promptTitle;
@synthesize promptText;
@synthesize customPlaceholderText;
@synthesize showEmailAddressField;
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATMessagePanelDelegate> *)aDelegate {
	self = [super initWithNibName:@"ATMessagePanelViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	[_toolbarShadowImage release], _toolbarShadowImage = nil;
	noEmailAddressAlert.delegate = nil;
	[noEmailAddressAlert release], noEmailAddressAlert = nil;
	invalidEmailAddressAlert.delegate = nil;
	[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
	emailRequiredAlert.delegate = nil;
	[emailRequiredAlert release], emailRequiredAlert = nil;
	[_interaction release], _interaction = nil;
	delegate = nil;
	[super dealloc];
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
	
	CALayer *l = self.view.layer;
	
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
	if (!parentWindow) {
		ATLogError(@"Unable to find parentWindow!");
	}
	if (originalPresentingWindow != parentWindow) {
		[originalPresentingWindow release], originalPresentingWindow = nil;
		originalPresentingWindow = [parentWindow retain];
	}
	
	[self setupScrollView];
	
	CGRect animationBounds = CGRectZero;
	CGPoint animationCenter = CGPointZero;
	
	CGAffineTransform t = [ATMessagePanelViewController viewTransformInWindow:parentWindow];
	self.window.transform = t;
	self.window.hidden = NO;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
	}
	[parentWindow resignKeyWindow];
	[self.window makeKeyAndVisible];
	animationBounds = parentWindow.bounds;
	animationCenter = parentWindow.center;
	
	// Animate in from above.
	self.window.bounds = animationBounds;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"] && originalPresentingWindow) {
		startingTintAdjustmentMode = originalPresentingWindow.tintAdjustmentMode;
		originalPresentingWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
	}
	CGPoint center = animationCenter;
	center.y = ceilf(center.y);
	
	CGRect endingFrame = [[UIScreen mainScreen] applicationFrame];
	
	[self positionInWindow];
	
	[self selectFirstResponder];
	
	self.window.center = CGPointMake(CGRectGetMidX(endingFrame), CGRectGetMidY(endingFrame));
	self.containerView.center = [self offscreenPositionOfView];
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	
	[self setupContainerView];
	
	UIView *shadowView = nil;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		UIScreen *screen = self.window.screen;
		CGRect statusFrame = [screen applicationFrame];
		CGRect shadowFrame = self.window.bounds;
		CGFloat offset = 0;
		if (statusFrame.origin.x > 0) {
			offset = statusFrame.origin.x;
		} else if (statusFrame.origin.y > 0) {
			offset = statusFrame.origin.y;
		}
		shadowFrame.origin.y -= offset;
		shadowFrame.size.height += offset;
		shadowView = [[UIView alloc] initWithFrame:shadowFrame];
		shadowView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
		shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	} else {
		shadowView = [[ATShadowView alloc] initWithFrame:self.window.bounds];
	}
	shadowView.tag = kMessagePanelGradientLayerTag;
	
	// Fix for iOS 8.
	// Should convert message panel to Auto Layout.
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"8.0"]) {
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
			CGRect originZero = self.window.frame;
			originZero.origin = CGPointZero;
			self.window.frame = originZero;
		}
	}
	
	[self.window addSubview:shadowView];
	[self.window sendSubviewToBack:shadowView];
	shadowView.alpha = 1.0;
	
	self.containerView.layer.cornerRadius = 10.0;
	l.backgroundColor = [UIColor whiteColor].CGColor;
	
	l.masksToBounds = YES;
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
		} else {
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
		}
#		pragma clang diagnostic pop
	}
	
	[UIView animateWithDuration:0.3 animations:^(void){
		self.containerView.center = newViewCenter;
		shadowView.alpha = 1.0;
	} completion:^(BOOL finished) {
		self.window.hidden = NO;
		
		[self selectFirstResponder];
	}];
	[shadowView release], shadowView = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidShowNotification object:self userInfo:nil];
}

- (void)selectFirstResponder {
	BOOL iPhoneIdiom = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL landScapeOrientation = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
	
	if (iPhoneIdiom && landScapeOrientation) {
		// Don't initial show keyboard
	} else {
		if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
			[self.emailField becomeFirstResponder];
		} else {
			[self.feedbackView becomeFirstResponder];
		}
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	if ([[ATConnect sharedConnection] tintColor] && [self.view respondsToSelector:@selector(setTintColor:)]) {
		[self.window setTintColor:[[ATConnect sharedConnection] tintColor]];
	}
	
	// Higher window level fixes issue where text selection loupe showed through Message Panel to the view beneath.
    self.window.windowLevel = UIWindowLevelNormal + 0.1;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:self.feedbackView];
	self.cancelButton = [[[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleCancel] autorelease];
	[self.cancelButton setAction:@selector(cancelPressed:) forTarget:self];
	
	self.sendButton = [[[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleSend] autorelease];
	[self.sendButton setAction:@selector(sendPressed:) forTarget:self];
	
	UIImage *toolbarShadowBase = [ATBackend imageNamed:@"at_message_toolbar_shadow"];
	UIImage *toolbarShadow = nil;
	if ([toolbarShadowBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		toolbarShadow = [toolbarShadowBase resizableImageWithCapInsets:UIEdgeInsetsMake(8, 0, 0, 128)];
	} else {
		toolbarShadow = [toolbarShadowBase stretchableImageWithLeftCapWidth:0 topCapHeight:8];
	}
	self.toolbarShadowImage.image = toolbarShadow;
	self.toolbarShadowImage.alpha = 0;
	
	NSMutableArray *toolbarItems = [[self.toolbar items] mutableCopy];
	[toolbarItems insertObject:self.cancelButton atIndex:0];
	[toolbarItems addObject:self.sendButton];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	if (self.promptTitle) {
		titleLabel.text = self.promptTitle;
	} else {
		titleLabel.text = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
	}
	titleLabel.adjustsFontSizeToFitWidth = YES;
	if ([titleLabel respondsToSelector:@selector(setMinimumScaleFactor:)]) {
		titleLabel.minimumScaleFactor = 0.5;
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		titleLabel.minimumFontSize = 10;
#		pragma clang diagnostic pop
	}
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.textColor = [UIColor colorWithRed:105/256. green:105/256. blue:105/256. alpha:1.0];
	titleLabel.shadowColor = [UIColor whiteColor];
	titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.opaque = NO;
	[titleLabel sizeToFit];
	CGRect titleFrame = titleLabel.frame;
	titleLabel.frame = titleFrame;
	
	UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
	[toolbarItems insertObject:titleButton atIndex:2];
	[titleButton release], titleButton = nil;
	[titleLabel release], titleLabel = nil;
		
	self.toolbar.items = toolbarItems;
	[toolbarItems release], toolbarItems = nil;
	
	self.toolbar.at_drawRectBlock = ^(NSObject *toolbar, CGRect rect) {
		UIColor *color = [UIColor colorWithRed:215/255. green:215/255. blue:215/255. alpha:1];
		UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.size.height - 1, rect.size.width, 1)];
		[color setFill];
		[rectanglePath fill];
	};
	
	[self updateSendButtonState];
	[super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//	return YES;
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (IBAction)sendPressed:(id)sender {
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	BOOL emailRequired = self.interaction ? [self.interaction.configuration[@"email_required"] boolValue] : [[ATConnect sharedConnection] emailRequired];
	
	if (self.showEmailAddressField && emailRequired && self.emailField.text.length == 0) {
		if (emailRequiredAlert) {
			emailRequiredAlert.delegate = nil;
			[emailRequiredAlert release], emailRequiredAlert = nil;
		}
		self.window.userInteractionEnabled = NO;
		self.window.layer.shouldRasterize = YES;
		self.window.layer.rasterizationScale = [[UIScreen mainScreen] scale];
		NSString *title = ATLocalizedString(@"Please enter an email address", @"Email is required and no email was entered alert title.");
		NSString *message = ATLocalizedString(@"An email address is required for us to respond.", @"Email is required and no email was entered alert message.");
		
		emailRequiredAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"OK", @"OK button title"), nil];
		[emailRequiredAlert show];
	} else if (self.showEmailAddressField && [self.emailField.text length] > 0 && ![ATUtilities emailAddressIsValid:self.emailField.text]) {
		if (invalidEmailAddressAlert) {
			[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
		}
		self.window.userInteractionEnabled = NO;
		self.window.layer.shouldRasterize = YES;
		self.window.layer.rasterizationScale = [[UIScreen mainScreen] scale];
		NSString *title = ATLocalizedString(@"Invalid Email Address", @"Invalid email dialog title.");
		NSString *message = nil;
		if (emailRequired) {
			message = ATLocalizedString(@"That doesn't look like an email address. An email address is required for us to respond.", @"Invalid email dialog message (email is required).");
		} else {
			message = ATLocalizedString(@"That doesn't look like an email address. An email address will help us respond.", @"Invalid email dialog message.");
		}
		invalidEmailAddressAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"OK", @"OK button title"), nil];
		[invalidEmailAddressAlert show];
	} else if (self.showEmailAddressField && (!self.emailField.text || [self.emailField.text length] == 0)) {
		if (noEmailAddressAlert) {
			noEmailAddressAlert.delegate = nil;
			[noEmailAddressAlert release], noEmailAddressAlert = nil;
		}
		self.window.userInteractionEnabled = NO;
		self.window.layer.shouldRasterize = YES;
		self.window.layer.rasterizationScale = [[UIScreen mainScreen] scale];
		NSString *title = ATLocalizedString(@"No email address?", @"Lack of email dialog title.");
		NSString *message = ATLocalizedString(@"An email address will help us respond.", @"Lack of email dialog message.");
		noEmailAddressAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Feedback", @"Send button title"), nil];
		BOOL useNativeTextField = [noEmailAddressAlert respondsToSelector:@selector(alertViewStyle)];
		UITextField *field = nil;
		
		if (useNativeTextField) {
			// iOS 5 and above.
			[noEmailAddressAlert setAlertViewStyle:2]; // UIAlertViewStylePlainTextInput
			field = [noEmailAddressAlert textFieldAtIndex:0];
			[field retain];
		} else {
			NSString *messagePadded = [NSString stringWithFormat:@"%@\n\n\n", message];
			[noEmailAddressAlert setMessage:messagePadded];
			field = [[UITextField alloc] initWithFrame:CGRectMake(16, 83, 252, 25)];
			field.font = [UIFont systemFontOfSize:18];
			field.textColor = [UIColor lightGrayColor];
			field.backgroundColor = [UIColor clearColor];
			field.keyboardAppearance = UIKeyboardAppearanceAlert;
			field.borderStyle = UITextBorderStyleRoundedRect;
		}
		field.keyboardType = UIKeyboardTypeEmailAddress;
		field.delegate = self;
		field.autocapitalizationType = UITextAutocapitalizationTypeNone;
		if (self.interaction.configuration[@"email_hint_text"]) {
			field.placeholder = self.interaction.configuration[@"email_hint_text"];
		} else {
			field.placeholder = ATLocalizedString(@"Email Address", @"Email address popup placeholder text.");
		}
		field.tag = kATEmailAlertTextFieldTag;
		
		if (!useNativeTextField) {
			[field becomeFirstResponder];
			[noEmailAddressAlert addSubview:field];
		} else {
			[field becomeFirstResponder];
		}
		[field release], field = nil;
		[noEmailAddressAlert sizeToFit];
		[noEmailAddressAlert show];
	} else {
		[self sendMessageAndDismiss];
	}
}

- (IBAction)cancelPressed:(id)sender {
	[self.delegate messagePanelDidCancel:self];
	[self dismissAnimated:YES completion:NULL withAction:ATMessagePanelDidCancel];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidCancelNotification object:self userInfo:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action {
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	CGPoint endingPoint = [self offscreenPositionOfView];
	
	UIView *gradientView = [self.window viewWithTag:kMessagePanelGradientLayerTag];
	
	CGFloat duration = 0;
	if (animated) {
		duration = 0.3;
	}
	[UIView animateWithDuration:duration animations:^(void){
		self.containerView.center = endingPoint;
		gradientView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.emailField resignFirstResponder];
		[self.feedbackView resignFirstResponder];
		UIView *gradientView = [self.window viewWithTag:kMessagePanelGradientLayerTag];
		[gradientView removeFromSuperview];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[presentingViewController.view setUserInteractionEnabled:YES];
		[self.window resignKeyWindow];
		[self.window removeFromSuperview];
		self.window.hidden = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:startingStatusBarStyle];
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"] && originalPresentingWindow) {
			originalPresentingWindow.tintAdjustmentMode = startingTintAdjustmentMode == UIViewTintAdjustmentModeDimmed ? UIViewTintAdjustmentModeAutomatic : startingTintAdjustmentMode;
		}
		[self teardown];
		[self release];
		
		if (completion) {
			completion();
		}
		[self.delegate messagePanel:self didDismissWithAction:action];
	}];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[self dismissAnimated:animated completion:completion withAction:ATMessagePanelWasDismissed];
}

- (void)dismiss:(BOOL)animated {
	[self dismissAnimated:animated completion:nil withAction:ATMessagePanelWasDismissed];
}

- (void)unhide:(BOOL)animated {
	self.window.hidden = NO;
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 1.0;
		} completion:^(BOOL complete){
			[self finishUnhide];
		}];
	} else {
		[self finishUnhide];
	}
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return [self shouldReturn:textField];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self.scrollView scrollRectToVisible:textField.frame animated:YES];
}


#pragma mark UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
	if (textView == self.feedbackView) {
		CGFloat minTextViewHeight = CGRectGetMaxY(self.scrollView.frame) - textView.frame.origin.y;
		CGSize oldContentSize = self.scrollView.contentSize;
		CGRect oldTextViewRect = textView.frame;
		
		CGSize sizedText = [textView sizeThatFits:CGSizeMake(textView.bounds.size.width, CGFLOAT_MAX)];
		sizedText.height = MAX(minTextViewHeight, sizedText.height);
		CGFloat heightDiff = oldTextViewRect.size.height - sizedText.height;
		
		CGSize newContentSize = oldContentSize;
		newContentSize.height -= heightDiff;
		newContentSize.width = scrollView.bounds.size.width;
		CGRect newTextViewFrame = oldTextViewRect;
		newTextViewFrame.size.height -= heightDiff;
		textView.frame = newTextViewFrame;
		if (![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			// Fix for iOS 4.
			textView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
		}
		if (!CGSizeEqualToSize(self.scrollView.contentSize, newContentSize)) {
			self.scrollView.contentSize = newContentSize;
		}
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[self.scrollView scrollRectToVisible:textView.frame animated:YES];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	if (self.scrollView.contentOffset.y != 0) {
		[UIView animateWithDuration:0.2 animations:^{
			self.toolbarShadowImage.alpha = 1;
		}];
	} else {
		[UIView animateWithDuration:0.0 animations:^{
			self.toolbarShadowImage.alpha = 0;
		}];
	}
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.window.layer.shouldRasterize = NO;
	self.window.layer.rasterizationScale = [[UIScreen mainScreen] scale];
	if (noEmailAddressAlert && [alertView isEqual:noEmailAddressAlert]) {
		BOOL useNativeTextField = [noEmailAddressAlert respondsToSelector:@selector(alertViewStyle)];
		
		UITextField *textField = nil;
		if (useNativeTextField) {
			textField = [noEmailAddressAlert textFieldAtIndex:0];
		} else {
			textField = (UITextField *)[noEmailAddressAlert viewWithTag:kATEmailAlertTextFieldTag];
		}
		if (textField) {
			self.emailField.text = textField.text;
		}
		noEmailAddressAlert.delegate = nil;
		[noEmailAddressAlert release], noEmailAddressAlert = nil;
		[self sendMessageAndDismiss];
	} else if (invalidEmailAddressAlert && [alertView isEqual:invalidEmailAddressAlert]) {
		self.window.userInteractionEnabled = YES;
		invalidEmailAddressAlert.delegate = nil;
		[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
		[self.emailField becomeFirstResponder];
	} else if (emailRequiredAlert && [alertView isEqual:emailRequiredAlert]) {
		self.window.userInteractionEnabled = YES;
		emailRequiredAlert.delegate = nil;
		[emailRequiredAlert release], emailRequiredAlert = nil;
		[self.emailField becomeFirstResponder];
	}
}

- (void)alertViewCancel:(UIAlertView *)alertView {
	self.window.layer.shouldRasterize = NO;
	self.window.layer.rasterizationScale = [[UIScreen mainScreen] scale];
	self.window.userInteractionEnabled = YES;
	if (noEmailAddressAlert && [alertView isEqual:noEmailAddressAlert]) {
		[noEmailAddressAlert release], noEmailAddressAlert = nil;
	} else if (invalidEmailAddressAlert && [alertView isEqual:invalidEmailAddressAlert]) {
		[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
	} else if (emailRequiredAlert && [alertView isEqual:emailRequiredAlert]) {
		[emailRequiredAlert release], emailRequiredAlert = nil;
	}
}

#pragma mark -

- (void)viewDidUnload {
	[self setToolbarShadowImage:nil];
	[super viewDidUnload];
}
@end

@implementation ATMessagePanelViewController (Private)

- (void)setupContainerView {

}

- (void)setupScrollView {
	CGFloat offsetY = 0;
	CGFloat horizontalPadding = 7;
	self.scrollView.backgroundColor = [UIColor colorWithRed:240/255. green:240/255. blue:240/255. alpha:1];
	self.scrollView.delegate = self;
	if (self.promptText) {
		CGRect containerFrame = self.scrollView.bounds;
		CGFloat labelPadding = 4;
		
		ATLabel *promptLabel = [[ATLabel alloc] initWithFrame:containerFrame];
		promptLabel.text = self.promptText;
		promptLabel.textColor = [UIColor colorWithRed:128/255. green:128/255. blue:128/255. alpha:1];
		promptLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:18];
		promptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptLabel.lineBreakMode = NSLineBreakByWordWrapping;
		promptLabel.numberOfLines = 0;
		CGSize fitSize = [promptLabel sizeThatFits:CGSizeMake(containerFrame.size.width - labelPadding*2, CGFLOAT_MAX)];
		containerFrame.size.height = fitSize.height + labelPadding*2;
		
		UIView *promptView = [[UIView alloc] initWithFrame:containerFrame];
		promptView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptView.backgroundColor = [UIColor whiteColor];
				
		CGRect labelFrame = CGRectInset(containerFrame, labelPadding, labelPadding);
		promptLabel.frame = labelFrame;
		[promptView addSubview:promptLabel];
		
		[self.scrollView addSubview:promptView];
		offsetY += promptView.bounds.size.height;
		[promptView release], promptView = nil;
		[promptLabel release], promptLabel = nil;
	}
	
	CGRect lineFrame = self.scrollView.bounds;
	lineFrame.size.height = 4;
	lineFrame.origin.y = offsetY;
	lineFrame.size.width += 1;
	UIView *blueLineView = [[UIView alloc] initWithFrame:lineFrame];
	blueLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_message_blue_line"]];
	blueLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.scrollView addSubview:blueLineView];
	offsetY += blueLineView.bounds.size.height;
	[blueLineView release], blueLineView = nil;
	
	if (self.showEmailAddressField) {
		offsetY += 5;
		CGFloat extraHorzontalPadding = 0;
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			// Needs a little extra to line up with new metrics on UITextViews.
			extraHorzontalPadding = 4;
		}
		CGRect emailFrame = self.scrollView.bounds;
		emailFrame.origin.x = horizontalPadding + extraHorzontalPadding;
		emailFrame.origin.y = offsetY;
		UIFont *emailFont = [UIFont systemFontOfSize:17];
		CGSize sizedEmail = CGSizeZero;
		NSString *sizingString = @"XXYyI|";
		if ([sizingString respondsToSelector:@selector(sizeWithAttributes:)]) {
			sizedEmail = [sizingString sizeWithAttributes:@{NSFontAttributeName:emailFont}];
		} else {
#			pragma clang diagnostic push
#			pragma clang diagnostic ignored "-Wdeprecated-declarations"
			sizedEmail = [sizingString sizeWithFont:emailFont];
#			pragma clang diagnostic pop
		}
		emailFrame.size.height = sizedEmail.height;
		emailFrame.size.width = emailFrame.size.width - (horizontalPadding + extraHorzontalPadding)*2;
		self.emailField = [[[UITextField alloc] initWithFrame:emailFrame] autorelease];
		if (self.interaction.configuration[@"email_hint_text"]) {
			self.emailField.placeholder = self.interaction.configuration[@"email_hint_text"];
		} else {
			if ([[ATConnect sharedConnection] emailRequired]) {
				self.emailField.placeholder = ATLocalizedString(@"Your Email (required)", @"Email Address Field Placeholder (email is required)");
			}
			else {
				self.emailField.placeholder = ATLocalizedString(@"Your Email", @"Email Address Field Placeholder");
			}
		}
		self.emailField.font = emailFont;
		self.emailField.adjustsFontSizeToFitWidth = YES;
		self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
		self.emailField.returnKeyType = UIReturnKeyNext;
		self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.emailField.backgroundColor = [UIColor clearColor];
		self.emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
		self.emailField.text = [[ATBackend sharedBackend] initialEmailAddressForMessagePanel];
		self.emailField.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		[self.scrollView addSubview:self.emailField];
		offsetY += self.emailField.bounds.size.height + 5;
		
		ATCustomView *thinBlueLineView = [[ATCustomView alloc] initWithFrame:CGRectZero];
		thinBlueLineView.at_drawRectBlock = ^(NSObject *caller, CGRect rect) {
			UIColor *color = [UIColor colorWithRed:133/255. green:149/255. blue:160/255. alpha:1];
			UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect:rect];
			[color setFill];
			[rectanglePath fill];
		};
		thinBlueLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		CGRect lineFrame = self.scrollView.bounds;
		CGFloat linePadding = 2;
		lineFrame.origin.x = linePadding;
		lineFrame.origin.y = offsetY;
		lineFrame.size.width = lineFrame.size.width - linePadding*2;
		lineFrame.size.height = 1;
		thinBlueLineView.frame = lineFrame;
		[self.scrollView addSubview:thinBlueLineView];
		offsetY += lineFrame.size.height;
		[thinBlueLineView release], thinBlueLineView = nil;
	}
	
	CGRect feedbackFrame = self.scrollView.bounds;
	feedbackFrame.origin.x = horizontalPadding;
	feedbackFrame.origin.y = offsetY;
	feedbackFrame.size.height = 20;
	feedbackFrame.size.width = feedbackFrame.size.width - horizontalPadding*2;
	self.feedbackView = [[[ATDefaultTextView alloc] initWithFrame:feedbackFrame] autorelease];
	
	if (![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		UIEdgeInsets insets = UIEdgeInsetsMake(0, -8, 0, 0);
		self.feedbackView.contentInset = insets;
	} else {
		self.feedbackView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	}
	self.feedbackView.clipsToBounds = YES;
	self.feedbackView.font = [UIFont systemFontOfSize:17];
	self.feedbackView.backgroundColor = [UIColor clearColor];
	self.feedbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.feedbackView.scrollEnabled = NO;
	self.feedbackView.delegate = self;
	[self.scrollView addSubview:self.feedbackView];
	offsetY += self.feedbackView.bounds.size.height;
	
	if (self.interaction.configuration[@"message_hint_text"]) {
		self.feedbackView.placeholder = self.interaction.configuration[@"message_hint_text"];
	}
	else if (self.customPlaceholderText) {
		self.feedbackView.placeholder = self.customPlaceholderText;
	} else {
		self.feedbackView.placeholder = ATLocalizedString(@"Feedback (required)", @"Feedback placeholder");
	}
	
	self.feedbackView.at_drawRectBlock = ^(NSObject *caller, CGRect rect) {
		ATDefaultTextView *textView = (ATDefaultTextView *)caller;
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetLineWidth(context, 0.5);
		CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:183/255. green:183/255. blue:183/255. alpha:1].CGColor);
		CGContextBeginPath(context);
		
		CGFloat startX = rect.origin.x;
		CGFloat endX = startX + rect.size.width;
		CGFloat lineHeight = textView.font.lineHeight;
		CGFloat offsetY = 4 - textView.font.descender;
		CGFloat scale = [UIScreen mainScreen].scale;
		
		NSUInteger firstLine = MAX(1, (textView.contentOffset.y/lineHeight));
		NSUInteger lastLine = (textView.contentOffset.y + textView.bounds.size.height)/lineHeight + 1;
		for (NSUInteger line = firstLine; line < lastLine; line++) {
			CGFloat lineY = round((offsetY + (lineHeight * line))*scale)/scale + 0.5;
			CGContextMoveToPoint(context, startX, lineY);
			CGContextAddLineToPoint(context, endX, lineY);
		}
		
		CGContextClosePath(context);
		CGContextStrokePath(context);
	};
	
	CGSize contentSize = CGSizeMake(self.scrollView.bounds.size.width, offsetY);
	
	self.scrollView.contentSize = contentSize;
	[self textViewDidChange:self.feedbackView];
}

- (void)teardown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.window removeFromSuperview];
	self.window = nil;
	
	self.cancelButton = nil;
	self.sendButton = nil;
	self.toolbar = nil;
	self.scrollView.delegate = nil;
	self.scrollView = nil;
	self.emailField.delegate = nil;
	self.emailField = nil;
	self.feedbackView.delegate = nil;
	self.feedbackView = nil;
	self.customPlaceholderText = nil;
	[originalPresentingWindow makeKeyWindow];
	[presentingViewController release], presentingViewController = nil;
	[originalPresentingWindow release], originalPresentingWindow = nil;
}

- (BOOL)shouldReturn:(UIView *)view {
	if (view == self.emailField) {
		[self.feedbackView becomeFirstResponder];
		return NO;
	} else if (view == self.feedbackView) {
		[self.feedbackView resignFirstResponder];
		return YES;
	}
	return NO;
}

- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen {
	UIApplication *application = [UIApplication sharedApplication];
	for (UIWindow *tmpWindow in [[application windows] reverseObjectEnumerator]) {
		if (tmpWindow.rootViewController || tmpWindow.isKeyWindow) {
			if (preferMainScreen && [tmpWindow respondsToSelector:@selector(screen)]) {
				if (tmpWindow.screen && [tmpWindow.screen isEqual:[UIScreen mainScreen]]) {
					return tmpWindow;
				}
			} else {
				return tmpWindow;
			}
		}
	}
	return nil;
}

- (UIWindow *)windowForViewController:(UIViewController *)viewController {
	UIWindow *result = nil;
	UIView *rootView = [viewController view];
	if (rootView.window) {
		result = rootView.window;
	}
	if (!result) {
		result = [self findMainWindowPreferringMainScreen:YES];
		if (!result) {
			result = [self findMainWindowPreferringMainScreen:NO];
		}
	}
	return result;
}

+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView {
	CGAffineTransform t = leafView.transform;
	UIView *s = leafView.superview;
	while (s && s != leafView.window) {
		t = CGAffineTransformConcat(t, s.transform);
		s = s.superview;
	}
	return atan2(t.b, t.a);
}

+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window {
	CGAffineTransform result = CGAffineTransformIdentity;
	do { // once
		if (!window) break;
		
		if ([[window rootViewController] view]) {
			CGFloat rotation = [ATMessagePanelViewController rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
			result = CGAffineTransformMakeRotation(rotation);
			break;
		}
		
		if ([[window subviews] count]) {
			for (UIView *v in [window subviews]) {
				if (!CGAffineTransformIsIdentity(v.transform)) {
					result = v.transform;
					break;
				}
			}
		}
	} while (NO);
	return result;
}

- (void)statusBarChanged:(NSNotification *)notification {
	[self positionInWindow];
}

- (void)keyboardWasShown:(NSNotification *)notification {
	NSValue *keyboardRectValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [keyboardRectValue CGRectValue];
	CGRect convertedKeyboardRect = [self.window convertRect:keyboardRect fromWindow:originalPresentingWindow];
	if (!CGRectEqualToRect(CGRectZero, convertedKeyboardRect)) {
		if (CGRectEqualToRect(lastKeyboardRect, convertedKeyboardRect)) {
			return;
		}
		lastKeyboardRect = convertedKeyboardRect;
		NSNumber *animationDuration = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
		if (animationDuration) {
			[self performSelector:@selector(positionInWindow) withObject:nil afterDelay:0.1];
		}
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	@autoreleasepool {
		[self retain];
		[self unhide:NO];
	}
}

- (void)applicationWillResignActive:(NSNotification *)notification {
	[self hide:NO];
}

- (void)feedbackChanged:(NSNotification *)notification {
	if (notification.object == self.feedbackView) {
		[self updateSendButtonState];
	}
}

- (void)hide:(BOOL)animated {
	[self retain];
	
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 0.0;
		} completion:^(BOOL finished) {
			[self finishHide];
		}];
	} else {
		[self finishHide];
	}
}

- (void)finishHide {
	self.window.alpha = 0.0;
	self.window.hidden = YES;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	[self.window removeFromSuperview];
}

- (void)finishUnhide {
	self.window.alpha = 1.0;
	[self.window makeKeyAndVisible];
	[self positionInWindow];
	if (self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}
	[self release];
}

- (void)sendMessageAndDismiss {
	[self.delegate messagePanel:self didSendMessage:self.feedbackView.text withEmailAddress:self.emailField.text];
	[self dismissAnimated:YES completion:NULL withAction:ATMessagePanelDidSendMessage];
}

- (void)updateSendButtonState {
	NSString *trimmedText = [self.feedbackView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	BOOL empty = [trimmedText length] == 0;
	self.sendButton.enabled = !empty;
	self.sendButton.style = empty ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone;
}
@end


@implementation ATMessagePanelViewController (Positioning)
- (BOOL)isIPhoneAppInIPad {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model isEqualToString:@"iPad"]) {
			return YES;
		}
	}
	return NO;
}

- (CGRect)onscreenRectOfView {
	BOOL constrainViewWidth = [self isIPhoneAppInIPad];
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat w = screenBounds.size.width;
	CGFloat h = screenBounds.size.height;
	
	BOOL isLandscape = NO;
	
	CGFloat windowWidth = 0.0;
	CGFloat windowHeight = 0.0;
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"8.0"]) {
		w = screenBounds.size.width;
		h = screenBounds.size.height;
		windowWidth = w;
		windowHeight = h;
		if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
			isLandscape = YES;
		}
	} else {
		switch (orientation) {
			case UIInterfaceOrientationLandscapeLeft:
			case UIInterfaceOrientationLandscapeRight:
				isLandscape = YES;
				windowWidth = h;
				windowHeight = w;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
			case UIInterfaceOrientationPortrait:
			default:
				windowWidth = w;
				windowHeight = h;
				break;
		}
	}
	
	CGFloat viewHeight = 0.0;
	CGFloat viewWidth = 0.0;
	CGFloat originY = 0.0;
	CGFloat originX = 0.0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		CGFloat keyboardHeight = lastKeyboardRect.size.height;
		
		viewWidth = 532;
		viewHeight = 328;
		
		originX = floorf((windowWidth - viewWidth) / 2.0);
		originY = floorf((windowHeight - viewHeight - keyboardHeight) / 2.0);
		
	} else {
		if (CGRectEqualToRect(CGRectZero, lastKeyboardRect)) {
			if (isLandscape) {
				CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
				viewHeight = windowHeight - 6 - MIN(statusBarSize.height, statusBarSize.width);
			} else {
				CGFloat landscapeKeyboardHeight = 162;
				CGFloat portraitKeyboardHeight = 216;
				viewHeight = self.view.window.bounds.size.height - (isLandscape ? landscapeKeyboardHeight + 8 - 6 : portraitKeyboardHeight + 8);
			}
		} else {
			CGFloat keyboardHeight = lastKeyboardRect.size.height;
			viewHeight = self.view.window.bounds.size.height - (isLandscape ? keyboardHeight + 8 - 6 : keyboardHeight + 8);
		}
		viewWidth = windowWidth - 12;
		originX = 6.0;
		if (constrainViewWidth) {
			viewWidth = MIN(320, windowWidth - 12);
		}
	}
	
	CGRect f = self.containerView.frame;
	f.origin.y = originY;
	f.origin.x = originX;
	f.size.width = viewWidth;
	f.size.height = viewHeight;
	
	return f;
}

- (CGPoint)offscreenPositionOfView {
	CGRect f = [self onscreenRectOfView];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGFloat statusBarHeight = MIN(statusBarSize.height, statusBarSize.width);
	CGFloat viewHeight = f.size.height;
	
	CGRect offscreenViewRect = f;
	offscreenViewRect.origin.y = -(viewHeight + statusBarHeight);
	CGPoint offscreenPoint = CGPointMake(CGRectGetMidX(offscreenViewRect), CGRectGetMidY(offscreenViewRect));
	
	return offscreenPoint;
}

- (void)positionInWindow {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(positionInWindow) withObject:nil waitUntilDone:NO];
		return;
	}
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	CGFloat angle = 0.0;
	CGRect newFrame = originalPresentingWindow.bounds;
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			newFrame.size.height -= statusBarSize.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = - M_PI / 2.0f;
			newFrame.origin.x += statusBarSize.width;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI / 2.0f;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			angle = 0.0;
			newFrame.origin.y += statusBarSize.height;
			newFrame.size.height -= statusBarSize.height;
			break;
	}
	[self.toolbar sizeToFit];
	
	CGRect toolbarBounds = self.toolbar.bounds;
	UIView *container = [self.view viewWithTag:kMessagePanelContainerViewTag];
	if (container != nil) {
		CGRect containerFrame = container.frame;
		containerFrame.origin.y = toolbarBounds.size.height;
		containerFrame.size.height = self.view.bounds.size.height - toolbarBounds.size.height;
		container.frame = containerFrame;
	}
	CGRect toolbarShadowImageFrame = self.toolbarShadowImage.frame;
	toolbarShadowImageFrame.origin.y = toolbarBounds.size.height;
	self.toolbarShadowImage.frame = toolbarShadowImageFrame;
	
	self.window.transform = CGAffineTransformMakeRotation(angle);
	
	// Fix for iOS 8.
	// Should convert message panel to Auto Layout.
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"8.0"]) {
		CGRect windowFrame;
		switch (orientation) {
			case UIInterfaceOrientationLandscapeLeft:
			case UIInterfaceOrientationLandscapeRight:
			{
				CGFloat statusBarShift = (orientation == UIInterfaceOrientationLandscapeLeft) ? statusBarSize.height : 0;
				windowFrame = CGRectMake(statusBarShift, 0, originalPresentingWindow.bounds.size.height - statusBarSize.height, originalPresentingWindow.bounds.size.width);
				break;
			}
			case UIInterfaceOrientationPortraitUpsideDown:
			case UIInterfaceOrientationPortrait:
			default:
				windowFrame = newFrame;
				break;
		}
		self.window.frame = windowFrame;
	} else {
		self.window.frame = newFrame;
	}
	
	self.containerView.frame = [self onscreenRectOfView];
	
	[self textViewDidChange:self.feedbackView];
	
	[self setupContainerView];
}
@end
