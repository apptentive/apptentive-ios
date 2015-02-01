//
//  ATMessagePanelNewUIViewController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessagePanelNewUIViewController.h"
#import "ATConnect.h"

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
#import "UIViewController+ATSwizzle.h"
#import "UIImage+ATImageEffects.h"
#import "ATInteraction.h"

#define USE_BLUR 0

@interface ATMessagePanelNewUIViewController ()

@end

@implementation ATMessagePanelNewUIViewController {
	ATLabel *promptLabel;
	ATCustomView *thinBlueLineView;
}

@synthesize backgroundImageView = _backgroundImageView;
@synthesize buttonFrame = _buttonFrame;
@synthesize sendButtonNewUI = _sendButtonNewUI;
@synthesize sendButtonPadding = _sendButtonPadding;
@synthesize cancelButtonNewUI = _cancelButtonNewUI;
@synthesize cancelButtonPadding = _cancelButtonPadding;

- (id)initWithDelegate:(NSObject<ATMessagePanelDelegate> *)aDelegate {
	self = [super initWithNibName:@"ATMessagePanelNewUIViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		delegate = aDelegate;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if USE_BLUR
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	UIImage *blurred = [self blurredBackgroundScreenshot];
	[self.backgroundImageView setImage:blurred];
#endif
}

- (void)dealloc {
	[_backgroundImageView release], _backgroundImageView = nil;
	[_buttonFrame release], _buttonFrame = nil;
	[_sendButtonNewUI release], _sendButtonNewUI = nil;
	[_cancelButtonNewUI release], _cancelButtonNewUI = nil;
	[_sendButtonPadding release], _sendButtonPadding = nil;
	[_cancelButtonPadding release], _cancelButtonPadding = nil;

	[promptLabel release], promptLabel = nil;
	[thinBlueLineView release], thinBlueLineView = nil;
	[super dealloc];
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	// Swizzle the presentingViewController's `didRotateFromInterfaceOrientation:` method to get a notifiction
	// when the background view finishes animating to the new orientation.
	//TODO: we would like to find a better solution to this.
	[newPresentingViewController at_swizzleMessagePanelDidRotateFromInterfaceOrientation];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentingViewControllerDidRotate:) name:ATMessagePanelPresentingViewControllerSwizzledDidRotateNotification object:nil];
	
	[super presentFromViewController:newPresentingViewController animated:animated];
	
	self.backgroundImageView.alpha = 0;
	[UIView animateWithDuration:0.3 animations:^(void){
		self.backgroundImageView.alpha = 1;
	} completion:^(BOOL finished) {

	}];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ATMessagePanelPresentingViewControllerSwizzledDidRotateNotification object:nil];
	[self retain];
	[super dismissAnimated:animated completion:completion withAction:action];
	
	CGFloat duration = animated ? 0.3 : 0;
	[UIView animateWithDuration:duration animations:^(void){
		self.backgroundImageView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self release];
	}];
}

- (void)presentingViewControllerDidRotate:(NSNotification *)notification {
	// Only pay attention to the presenting view controller.
	if (!presentingViewController) {
		return;
	}
	CGRect f = presentingViewController.view.frame;
	CGAffineTransform t = presentingViewController.view.transform;
	if (CGRectEqualToRect(lastSeenPresentingViewControllerFrame, f) && CGAffineTransformEqualToTransform(lastSeenPresentingViewControllerTransform, t)) {
		return;
	}
	lastSeenPresentingViewControllerFrame = f;
	lastSeenPresentingViewControllerTransform = t;
#if USE_BLUR
	UIImage *blurred = [self blurredBackgroundScreenshot];
	[UIView transitionWithView:self.backgroundImageView
					  duration:0.3f
					   options:UIViewAnimationOptionTransitionCrossDissolve
					animations:^{
						self.backgroundImageView.image = blurred;
					} completion:nil];
#endif
}

- (UIImage *)blurredBackgroundScreenshot {
	UIImage *screenshot = [ATUtilities imageByTakingScreenshotIncludingBlankStatusBarArea:NO excludingWindow:self.window];
	UIColor *tintColor = [UIColor colorWithWhite:0 alpha:0.1];
	UIImage *blurred = [screenshot at_applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:3.8 maskImage:nil];
	UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	blurred = [ATUtilities imageByRotatingImage:blurred toInterfaceOrientation:interfaceOrientation];
	
	return blurred;
}

- (void)setupContainerView {
	self.containerView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
	self.containerView.layer.cornerRadius = 7.0;
	
	NSInteger buttonHeight = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ? 44 : 30;
	
	CGFloat pixelLineWidth = [[UIScreen mainScreen] scale] == 2 ? 0.25 : 0.5;
	
	CGRect buttonFrame = self.containerView.bounds;
	buttonFrame.size.height = buttonHeight - pixelLineWidth;
	buttonFrame.origin.y = self.containerView.bounds.size.height - buttonFrame.size.height + pixelLineWidth;
	self.buttonFrame.frame = buttonFrame;
	
	CGRect leftFrame = self.buttonFrame.bounds;
	leftFrame.size.width = leftFrame.size.width / 2 - pixelLineWidth;
	self.cancelButtonPadding.frame = leftFrame;
	self.cancelButtonNewUI.frame = self.cancelButtonPadding.bounds;
	
	CGRect rightFrame = self.buttonFrame.bounds;
	rightFrame.origin.x = rightFrame.size.width / 2 + pixelLineWidth;
	rightFrame.size.width = rightFrame.size.width / 2 - pixelLineWidth;
	self.sendButtonPadding.frame = rightFrame;
	self.sendButtonNewUI.frame = self.sendButtonPadding.bounds;
	
	// Resize view
	CGRect viewFrame = self.containerView.bounds;
	viewFrame.size.height -= buttonHeight;
	self.view.frame = viewFrame;
	
	[self setupScrollView];
}

- (void)setupScrollView {
	CGFloat offsetY = 0;
	CGFloat horizontalPadding = 7;
	self.scrollView.backgroundColor = [UIColor whiteColor];
	self.view.backgroundColor = [UIColor clearColor];
	self.scrollView.delegate = self;
	
	if (self.interaction.configuration[@"submit_text"]) {
		[self.sendButtonNewUI setTitle:self.interaction.configuration[@"submit_text"] forState:UIControlStateNormal];
	} else {
		NSString *sendTitle = ATLocalizedString(@"Send", @"Button title to Send a message using the feedback dialog.");
		[self.sendButtonNewUI setTitle:sendTitle forState:UIControlStateNormal];
	}
	
	if (self.interaction.configuration[@"decline_text"]) {
		[self.cancelButtonNewUI setTitle:self.interaction.configuration[@"decline_text"] forState:UIControlStateNormal];
	} else {
		NSString *cancelTitle = ATLocalizedString(@"Cancel", @"Button title to Cancel a feedback dialog message.");
		[self.cancelButtonNewUI setTitle:cancelTitle forState:UIControlStateNormal];
	}
	
	CGFloat width = CGRectGetWidth(self.scrollView.bounds);
	
	if (self.promptText) {
		UIEdgeInsets labelInsets = UIEdgeInsetsMake(10, 12, 10, 12);
		
		if (!promptLabel) {
			promptLabel = [[ATLabel alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
			promptLabel.text = self.promptText;
			promptLabel.textColor = [UIColor colorWithRed:128/255. green:128/255. blue:128/255. alpha:1];
			promptLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			promptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			promptLabel.lineBreakMode = NSLineBreakByWordWrapping;
			promptLabel.numberOfLines = 0;
		}
		
		CGSize fitSize = [promptLabel sizeThatFits:CGSizeMake(width - labelInsets.left - labelInsets.right, CGFLOAT_MAX)];
		CGFloat promptContainerHeight = fitSize.height + labelInsets.top + labelInsets.bottom;
		
		CGRect promptContainerBounds = CGRectMake(0, 0, width, promptContainerHeight);
		CGRect promptContainerFrame = CGRectOffset(promptContainerBounds, 0, offsetY);
		CGRect promptLabelFrame = UIEdgeInsetsInsetRect(promptContainerBounds, labelInsets);
		
		if (!self.promptContainer) {
			self.promptContainer = [[[UIView alloc] initWithFrame:promptContainerFrame] autorelease];
			self.promptContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			self.promptContainer.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1];
			[self.promptContainer addSubview:promptLabel];
			[self.scrollView addSubview:self.promptContainer];
		}
		self.promptContainer.frame = promptContainerFrame;
		promptLabel.frame = promptLabelFrame;
		
		offsetY += CGRectGetHeight(self.promptContainer.bounds);
	}
			
	if (self.showEmailAddressField) {
		offsetY += 5;
		CGFloat extraHorzontalPadding = 0;
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			// Needs a little extra to line up with new metrics on UITextViews.
			extraHorzontalPadding = 4;
		}
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
		CGRect emailFrame = CGRectMake(0, offsetY, width, sizedEmail.height);
		emailFrame = CGRectInset(emailFrame, horizontalPadding+extraHorzontalPadding, 0);
		
		if (!self.emailField) {
			self.emailField = [[[UITextField alloc] initWithFrame:emailFrame] autorelease];
			self.emailField.delegate = self;
			if (self.interaction.configuration[@"email_hint_text"]) {
				self.emailField.placeholder = self.interaction.configuration[@"email_hint_text"];
			}
			else if ([[ATConnect sharedConnection] emailRequired]) {
				self.emailField.placeholder = ATLocalizedString(@"Email (required)", @"Email Address Field Placeholder (email is required)");
			}
			else {
				self.emailField.placeholder = ATLocalizedString(@"Email", @"Email Address Field Placeholder");
			}
			[self.emailField setValue:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
			
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
		}
		self.emailField.frame = emailFrame;
		offsetY += CGRectGetHeight(self.emailField.bounds) + 5;
		
		if (!thinBlueLineView) {
			thinBlueLineView = [[ATCustomView alloc] initWithFrame:CGRectZero];
			thinBlueLineView.at_drawRectBlock = ^(NSObject *caller, CGRect rect) {
				UIColor *color = [UIColor colorWithRed:133/255. green:149/255. blue:160/255. alpha:1];
				UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect:rect];
				[color setFill];
				[rectanglePath fill];
			};
			thinBlueLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			[self.scrollView addSubview:thinBlueLineView];
		}
		CGFloat linePadding = 2;
		CGRect lineFrame = CGRectMake(0, offsetY, width, 1);
		lineFrame = CGRectInset(lineFrame, linePadding, 0);
		thinBlueLineView.frame = lineFrame;
		
		offsetY += CGRectGetHeight(lineFrame);
	}
	
	CGRect feedbackFrame = CGRectMake(0, offsetY, width, 20);
	feedbackFrame = CGRectInset(feedbackFrame, horizontalPadding, 0);
	if (!self.feedbackView) {
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
	}
	self.feedbackView.frame = feedbackFrame;
	offsetY += CGRectGetHeight(self.feedbackView.bounds);
	
	if (self.interaction.configuration[@"message_hint_text"]) {
		self.feedbackView.placeholder = self.interaction.configuration[@"message_hint_text"];
	}
	else if (self.customPlaceholderText) {
		self.feedbackView.placeholder = self.customPlaceholderText;
	} else {
		self.feedbackView.placeholder = ATLocalizedString(@"How can we help? (required)", @"First feedback placeholder text.");
	}
	self.feedbackView.placeholderColor = [self.view tintColor];
	
	CGSize contentSize = CGSizeMake(self.scrollView.bounds.size.width, offsetY);
	
	self.scrollView.contentSize = contentSize;
	[self textViewDidChange:self.feedbackView];
}

- (void)updateSendButtonState {
	NSString *trimmedText = [self.feedbackView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	self.sendButtonNewUI.enabled = [trimmedText length] > 0;
}

@end
