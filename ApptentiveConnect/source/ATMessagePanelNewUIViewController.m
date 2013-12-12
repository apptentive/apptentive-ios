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

@interface ATMessagePanelNewUIViewController ()

@end

@implementation ATMessagePanelNewUIViewController

- (id)initWithDelegate:(NSObject<ATMessagePanelDelegate> *)aDelegate {
	self = [super initWithNibName:@"ATMessagePanelNewUIViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		delegate = aDelegate;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupContainerView {
	self.containerView.backgroundColor = [UIColor clearColor];
	self.containerView.layer.cornerRadius = 10.0;
	
	NSInteger buttonHeight = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ? 44 : 30;
	
	CGRect buttonFrame = self.containerView.bounds;
	buttonFrame.size.height = buttonHeight;
	buttonFrame.origin.y = self.containerView.bounds.size.height - buttonFrame.size.height + 1;
	self.buttonFrame.frame = buttonFrame;
	
	CGRect leftFrame = self.buttonFrame.bounds;
	leftFrame.size.width = leftFrame.size.width / 2;
	self.cancelButtonPading.frame = leftFrame;
	self.cancelButtonNewUI.frame = self.cancelButtonPading.bounds;
	
	CGRect rightFrame = self.buttonFrame.bounds;
	rightFrame.origin.x = rightFrame.size.width / 2 + 1;
	rightFrame.size.width = rightFrame.size.width / 2 - 1;
	self.sendButtonPading.frame = rightFrame;
	self.sendButtonNewUI.frame = self.sendButtonPading.bounds;
	
	// Resize view
	CGRect viewFrame = self.containerView.bounds;
	viewFrame.size.height -= buttonHeight;
	self.view.bounds = viewFrame;
	
	// Resize prompt
	self.promptContainer.clipsToBounds = YES;
	NSInteger promptHeight = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ? 100 : 40;
	CGRect prompt = self.promptContainer.frame;
	prompt.size.height = promptHeight;
	self.promptContainer.frame = prompt;
	// TODO: resize text
	
	// Resize scrollview
	CGRect scrollFrame = self.view.bounds;
	scrollFrame.origin.y = self.promptContainer.frame.size.height;
	scrollFrame.size.height -= self.promptContainer.frame.size.height;
	self.scrollView.frame = scrollFrame;
}

- (void)setupScrollView {
	CGFloat offsetY = 0;
	CGFloat horizontalPadding = 7;
	self.scrollView.backgroundColor = [UIColor whiteColor];
	self.view.backgroundColor = [UIColor clearColor];
	self.scrollView.delegate = self;
	
	CGRect promptContainerFrame;
	if (self.promptText) {
		CGRect containerFrame = self.scrollView.bounds;
		CGFloat labelPadding = 4;
		
		ATLabel *promptLabel = [[ATLabel alloc] initWithFrame:containerFrame];
		promptLabel.text = self.promptText;
		promptLabel.textColor = [UIColor colorWithRed:128/255. green:128/255. blue:128/255. alpha:1];
		promptLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:18];
		promptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptLabel.lineBreakMode = UILineBreakModeWordWrap;
		promptLabel.numberOfLines = 0;
		CGSize fitSize = [promptLabel sizeThatFits:CGSizeMake(containerFrame.size.width - labelPadding*2, CGFLOAT_MAX)];
		containerFrame.size.height = fitSize.height + labelPadding*2;
		
		UIView *promptContainer = [[UIView alloc] initWithFrame:containerFrame];
		promptContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptContainer.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1];
		
		CGRect labelFrame = CGRectInset(containerFrame, labelPadding, labelPadding);
		promptLabel.frame = labelFrame;
		[promptContainer addSubview:promptLabel];
		
		self.promptContainer = promptContainer;
		[self.view addSubview:self.promptContainer];
		offsetY += promptContainer.bounds.size.height;
		promptContainerFrame = promptContainer.frame;
		[promptContainer release], promptContainer = nil;
		[promptLabel release], promptLabel = nil;
	}
			
	if (self.showEmailAddressField) {
		offsetY += 5;
		CGFloat extraHorzontalPadding = 0;
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			// Needs a little extra to line up with new metrics on UITextViews.
			extraHorzontalPadding = 4;
		}
		CGRect emailFrame = self.scrollView.bounds;
		emailFrame.origin.x = horizontalPadding + extraHorzontalPadding;
		emailFrame.origin.y = 5;
		UIFont *emailFont = [UIFont systemFontOfSize:17];
		CGSize sizedEmail = [@"XXYyI|" sizeWithFont:emailFont];
		emailFrame.size.height = sizedEmail.height;
		emailFrame.size.width = emailFrame.size.width - (horizontalPadding + extraHorzontalPadding)*2;
		self.emailField = [[[UITextField alloc] initWithFrame:emailFrame] autorelease];
		if ([[ATConnect sharedConnection] emailRequired]) {
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
		self.emailField.text = [self.delegate initialEmailAddressForMessagePanel:self];
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
		lineFrame.origin.y = self.emailField.frame.size.height + 5;
		lineFrame.size.width = lineFrame.size.width - linePadding*2;
		lineFrame.size.height = 1;
		thinBlueLineView.frame = lineFrame;
		[self.scrollView addSubview:thinBlueLineView];
		offsetY += lineFrame.size.height;
		[thinBlueLineView release], thinBlueLineView = nil;
	}
	
	CGRect feedbackFrame = self.scrollView.bounds;
	feedbackFrame.origin.x = horizontalPadding;
	feedbackFrame.origin.y = self.emailField.frame.size.height + 5;
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
	
	if (self.customPlaceholderText) {
		self.feedbackView.placeholder = self.customPlaceholderText;
	} else {
		self.feedbackView.placeholder = ATLocalizedString(@"Message (required)", @"Message placeholder in iOS 7 message panel");
	}
	self.feedbackView.placeholderColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
	
	CGSize contentSize = CGSizeMake(self.scrollView.bounds.size.width, offsetY);
	
	self.scrollView.contentSize = contentSize;
	[self textViewDidChange:self.feedbackView];
}

@end
