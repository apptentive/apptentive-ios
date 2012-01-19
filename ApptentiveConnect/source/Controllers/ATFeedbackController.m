//
//  ATFeedbackController.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATFeedbackController.h"
#import "ATContactStorage.h"
#import "ATContactUpdater.h"
#import "ATCustomButton.h"
#import "ATToolbar.h"
#import "ATDefaultTextView.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATFeedback.h"
#import "ATFeedbackMetrics.h"
#import "ATHUDView.h"
#import "ATInfoViewController.h"
#import "ATSimpleImageViewController.h"
#import "ATUtilities.h"
#import "ATShadowView.h"
#import <QuartzCore/QuartzCore.h>


#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

enum {
	kFeedbackPaperclipTag = 400,
	kFeedbackPaperclipBackgroundTag = 401,
	kFeedbackPhotoFrameTag = 402,
	kFeedbackPhotoControlTag = 403,
	kFeedbackPhotoPreviewTag = 404,
	kContainerViewTag = 1009,
	kATEmailAlertTextFieldTag = 1010,
	kFeedbackGradientLayerTag = 1011,
};

@interface ATFeedbackController (Private)
- (void)teardown;
- (void)setupFeedback;
- (BOOL)shouldReturn:(UIView *)view;
- (UIWindow *)windowForViewController:(UIViewController *)viewController;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)statusBarChanged:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (BOOL)shouldShowPaperclip;
- (BOOL)shouldShowThumbnail;
- (void)captureFeedbackState;
- (void)hide:(BOOL)animated;
- (void)finishHide;
- (void)finishUnhide;
- (CGRect)photoControlFrame;
- (CGFloat)attachmentVerticalOffset;
- (void)updateThumbnail;
- (void)sendFeedbackAndDismiss;
- (void)updateSendButtonState;
@end

@interface ATFeedbackController (Positioning)
- (CGRect)onscreenRectOfView;
- (CGPoint)offscreenPositionOfView;
- (void)positionInWindow;
@end

@implementation ATFeedbackController
@synthesize feedbackContainerView;
@synthesize window=window$;
@synthesize doneButton=doneButton$;
@synthesize toolbar=toolbar$;
@synthesize redLineView=redLineView$;
@synthesize grayLineView=grayLineView$;
@synthesize backgroundView=backgroundView$;
@synthesize scrollView=scrollView$;
@synthesize emailField=emailField$;
@synthesize feedbackView=feedbackView$;
@synthesize logoControl=logoControl$;
@synthesize logoImageView=logoImageView$;
@synthesize taglineLabel=taglineLabel$;
@synthesize attachmentOptions;
@synthesize feedback=feedback;
@synthesize customPlaceholderText=customPlaceholderText$;
@synthesize showEmailAddressField;

- (id)init {
	self = [super initWithNibName:@"ATFeedbackController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		self.attachmentOptions = ATFeedbackAllowPhotoAttachment | ATFeedbackAllowTakePhotoAttachment;
	}
	return self;
}

- (void)dealloc {
	[self teardown];
	[super dealloc];
}

- (oneway void)release {
	[super release];
}

- (id)retain {
	return [super retain];
}

- (void)setFeedback:(ATFeedback *)newFeedback {
    if (feedback != newFeedback) {
        [feedback release];
        feedback = nil;
        feedback = [newFeedback retain];
        [self setupFeedback];
    }
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	if (self.showEmailAddressField == NO) {
		CGRect emailFrame = [self.emailField frame];
		CGRect feedbackFrame = [self.feedbackContainerView frame];
		feedbackFrame.size.height += (feedbackFrame.origin.y - emailFrame.origin.y);
		feedbackFrame.origin.y = emailFrame.origin.y;
		[self.emailField setHidden:YES];
		[self.grayLineView setHidden:YES];
		[self.feedbackContainerView setFrame:feedbackFrame];
	}
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
	CALayer *l = self.view.layer;
	
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
	self.window.transform = [ATFeedbackController viewTransformInWindow:parentWindow];
	self.window.hidden = NO;
	[parentWindow resignKeyWindow];
	[self.window makeKeyAndVisible];
	
	
	// Animate in from above.
	self.window.bounds = parentWindow.bounds;
	self.window.windowLevel = UIWindowLevelNormal;
	CGPoint center = parentWindow.center;
	center.y = ceilf(center.y);
	
	CGRect endingFrame = [[UIScreen mainScreen] applicationFrame];
	
	CGPoint startingPoint = CGPointZero;
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
    switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			startingPoint = CGPointMake(center.x, center.y + self.window.bounds.size.height);
			break;
        case UIInterfaceOrientationLandscapeLeft:
			startingPoint = CGPointMake(center.x - self.window.bounds.size.width, center.y);
            break;
        case UIInterfaceOrientationLandscapeRight:
			startingPoint = CGPointMake(center.x + self.window.bounds.size.width, center.y);
            break;
        default: // as UIInterfaceOrientationPortrait
			startingPoint = CGPointMake(center.x, center.y - parentWindow.bounds.size.height);
            break;
    }
	
	[self positionInWindow];
	
	if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}

	self.window.center = CGPointMake(CGRectGetMidX(endingFrame), CGRectGetMidY(endingFrame));
	self.view.center = [self offscreenPositionOfView];
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));

	ATShadowView *shadowView = [[ATShadowView alloc] initWithFrame:self.window.bounds];
	shadowView.tag = kFeedbackGradientLayerTag;
	[self.window addSubview:shadowView];
	[self.window sendSubviewToBack:shadowView];
	shadowView.alpha = 1.0;
	
	l.cornerRadius = 10.0;
	l.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dialog_paper_bg"]].CGColor;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	}
	
	[UIView beginAnimations:@"animateIn" context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	self.view.center = newViewCenter;
	shadowView.alpha = 1.0;
	[UIView commitAnimations];
	[shadowView release], shadowView = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidShowWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeFeedback] forKey:ATFeedbackWindowTypeKey]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:self.feedbackView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactInfoChanged:) name:ATContactUpdaterFinished object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenshotChanged:) name:ATImageViewChoseImage object:nil];
	
	self.redLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dotted_red_line"]];
	self.grayLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_gray_line"]];
	self.redLineView.opaque = NO;
	self.grayLineView.opaque = NO;
	self.redLineView.layer.opaque = NO;
	self.grayLineView.layer.opaque = NO;
	
	self.logoImageView.image = [ATBackend imageNamed:@"at_apptentive_icon_small"];
	self.taglineLabel.text = ATLocalizedString(@"Feedback Powered by Apptentive", @"Tagline text");
	
	if ([self shouldShowPaperclip]) {
		CGRect viewBounds = self.view.bounds;
		UIImage *paperclipBackground = [ATBackend imageNamed:@"at_paperclip_background"];
		paperclipBackgroundView = [[UIImageView alloc] initWithImage:paperclipBackground];
		[self.view addSubview:paperclipBackgroundView];
		paperclipBackgroundView.frame = CGRectMake(viewBounds.size.width - paperclipBackground.size.width + 3.0, [self attachmentVerticalOffset] + 6.0, paperclipBackground.size.width, paperclipBackground.size.height);
		paperclipBackgroundView.tag = kFeedbackPaperclipBackgroundTag;
		paperclipBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
				
		UIImage *paperclip = [ATBackend imageNamed:@"at_paperclip_foreground"];
		paperclipView = [[UIImageView alloc] initWithImage:paperclip];
		[self.view addSubview:paperclipView];
		paperclipView.frame = CGRectMake(viewBounds.size.width - paperclip.size.width + 6.0, [self attachmentVerticalOffset], paperclip.size.width, paperclip.size.height);
		paperclipView.tag = kFeedbackPaperclipTag;
		paperclipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		
		photoControl = [[UIControl alloc] initWithFrame:[self photoControlFrame]];
		photoControl.tag = kFeedbackPhotoControlTag;
		[photoControl addTarget:self action:@selector(photoPressed:) forControlEvents:UIControlEventTouchUpInside];
		photoControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:photoControl];
	}
	
	ATCustomButton *cancelButton = [[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleCancel];
	[cancelButton setAction:@selector(cancelFeedback:) forTarget:self];
	
	ATCustomButton *sendButton = [[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleSend];
	[sendButton setAction:@selector(donePressed:) forTarget:self];
	self.doneButton = sendButton;
	
	NSMutableArray *toolbarItems = [[self.toolbar items] mutableCopy];
	[toolbarItems insertObject:cancelButton atIndex:0];
	[toolbarItems addObject:sendButton];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.text = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
	titleLabel.textAlignment = UITextAlignmentCenter;
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
	
	self.emailField.placeholder = ATLocalizedString(@"Email Address", @"Email Address Field Placeholder");
	
    if (self.customPlaceholderText) {
        self.feedbackView.placeholder = self.customPlaceholderText;
    } else {
        self.feedbackView.placeholder = ATLocalizedString(@"Feedback (required)", @"Feedback placeholder");
    }
	
	self.toolbar.items = toolbarItems;
	[toolbarItems release], toolbarItems = nil;
	[cancelButton release], cancelButton = nil;
	[sendButton release], sendButton = nil;
	
	[self setupFeedback];
	[self updateSendButtonState];
    [super viewDidLoad];
}

- (void)viewDidUnload {
	[self setFeedbackContainerView:nil];
    [super viewDidUnload];
	[self teardown];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	return YES;
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (IBAction)donePressed:(id)sender {
	[self captureFeedbackState];
    if (self.showEmailAddressField && (!self.feedback.email || [self.feedback.email length] == 0)) {
		self.window.windowLevel = UIWindowLevelNormal;
        NSString *title = NSLocalizedString(@"No email address?", @"Lack of email dialog title.");
        NSString *message = NSLocalizedString(@"We can't respond without one.\n\n\n", @"Lack of email dialog message.");
        UIAlertView *emailAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil  otherButtonTitles:NSLocalizedString(@"Send Feedback", @"Send button title"), nil];
        
        UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(16, 83, 252, 25)];
        field.font = [UIFont systemFontOfSize:18];
		field.textColor = [UIColor lightGrayColor];
        field.backgroundColor = [UIColor clearColor];
        field.keyboardAppearance = UIKeyboardAppearanceAlert;
		field.keyboardType = UIKeyboardTypeEmailAddress;
        field.delegate = self;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.placeholder = NSLocalizedString(@"Email Address", @"Email address popup placeholder text.");
        field.borderStyle = UITextBorderStyleRoundedRect;
        field.tag = kATEmailAlertTextFieldTag;
        [field becomeFirstResponder];
        [emailAlert addSubview:field];
        [field release], field = nil;
        [emailAlert sizeToFit];
        [emailAlert show];
        [emailAlert release];
    } else {
        [self sendFeedbackAndDismiss];
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackEventTappedSend] forKey:ATFeedbackWindowHideEventKey]];
}

- (IBAction)photoPressed:(id)sender {
	[self.emailField resignFirstResponder];
    [self.feedbackView resignFirstResponder];
	[self hide:YES];
    [self captureFeedbackState];
    ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithFeedback:self.feedback feedbackController:self];
	[presentingViewController presentModalViewController:vc animated:YES];
    [vc release];
}

- (IBAction)showInfoView:(id)sender {
	[self hide:YES];
    ATInfoViewController *vc = [[ATInfoViewController alloc] initWithFeedbackController:self];
    [presentingViewController presentModalViewController:vc animated:YES];
    [vc release];
}

- (IBAction)cancelFeedback:(id)sender {
    [self captureFeedbackState];
	[self dismiss:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackEventTappedCancel] forKey:ATFeedbackWindowHideEventKey]];
}

- (void)dismiss:(BOOL)animated {
    [self captureFeedbackState];
	
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	CGPoint endingPoint = [self offscreenPositionOfView];
	
	[self retain]; 
	UIView *gradientView = [self.window viewWithTag:kFeedbackGradientLayerTag];
	
	[UIView beginAnimations:@"animateOut" context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	self.view.center = endingPoint;
	gradientView.alpha = 0.0;
	[UIView commitAnimations];
}

- (void)unhide:(BOOL)animated {
	self.window.windowLevel = UIWindowLevelNormal;
	self.window.hidden = NO;
	if (animated) {
		[UIView beginAnimations:@"windowUnhide" context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		self.window.alpha = 1.0;
		[UIView commitAnimations];
	} else {
		[self finishUnhide];
	}
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *textField = (UITextField *)[alertView viewWithTag:kATEmailAlertTextFieldTag];
    if (textField) {
        self.feedback.email = textField.text;
        [self sendFeedbackAndDismiss];
    }
}
@end

@implementation ATFeedbackController (Private)

- (void)teardown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.window removeFromSuperview];
	self.window = nil;
	
	[paperclipBackgroundView removeFromSuperview];
	[paperclipBackgroundView release], paperclipBackgroundView = nil;
	
	[paperclipView removeFromSuperview];
	[paperclipView release], paperclipView = nil;
	
	[photoFrameView removeFromSuperview];
	[photoFrameView release], photoFrameView = nil;
	
	[photoControl removeFromSuperview];
	[photoControl release], photoControl = nil;
	
	
	[feedbackContainerView release], feedbackContainerView = nil;
	
	self.doneButton = nil;
	self.toolbar = nil;
	self.redLineView = nil;
	self.grayLineView = nil;
	self.backgroundView = nil;
	self.scrollView = nil;
	self.emailField = nil;
	self.feedbackView = nil;
	self.logoControl = nil;
	self.logoImageView = nil;
	self.taglineLabel = nil;
	[currentImage release], currentImage = nil;
	[[self windowForViewController:presentingViewController] makeKeyAndVisible];
	[presentingViewController release], presentingViewController = nil;
}

- (void)setupFeedback {
    if (self.feedbackView && [self.feedbackView isDefault] && self.feedback.text) {
        self.feedbackView.text = self.feedback.text;
    }
    if (self.emailField && (!self.emailField.text || [@"" isEqualToString:self.emailField.text]) && self.feedback.email) {
        self.emailField.text = self.feedback.email;
    }
	[self updateThumbnail];
}

- (BOOL)shouldReturn:(UIView *)view {
    if (view == self.emailField) {
        [self.feedbackView becomeFirstResponder];
        return NO;
    } else if (view == self.feedbackView) {
		[self.feedbackView resignFirstResponder];
        return YES;
    }
    return YES;
}

- (UIWindow *)windowForViewController:(UIViewController *)viewController {
	UIWindow *result = nil;
	UIView *rootView = [viewController view];
	if (rootView.window) {
		result = rootView.window;
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
            CGFloat rotation = [ATFeedbackController rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
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

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([animationID isEqualToString:@"animateIn"]) {
		self.window.hidden = NO;
		if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
			[self.emailField becomeFirstResponder];
		} else {
			[self.feedbackView becomeFirstResponder];
		}
	} else if ([animationID isEqualToString:@"animateOut"]) {
		UIView *gradientView = [self.window viewWithTag:kFeedbackGradientLayerTag];
		[gradientView removeFromSuperview];	

		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[presentingViewController.view setUserInteractionEnabled:YES];
		[self.window resignKeyWindow];
		[self.window removeFromSuperview];
		self.window.hidden = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:startingStatusBarStyle];
		[self release];
	} else if ([animationID isEqualToString:@"windowHide"]) {
		[self finishHide];
	} else if ([animationID isEqualToString:@"windowUnhide"]) {
		[self finishUnhide];
	}
}

- (void)statusBarChanged:(NSNotification *)notification {
	[self positionInWindow];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (self.window.hidden == NO) {
		[self retain];
		[self unhide:NO];
	}
	[pool release], pool = nil;
}

- (BOOL)shouldShowPaperclip {
	return (attachmentOptions != 0);
}

- (BOOL)shouldShowThumbnail {
	return (feedback.screenshot != nil);
}

- (void)feedbackChanged:(NSNotification *)notification {
    if (notification.object == self.feedbackView) {
		[self updateSendButtonState];
    }
}

- (void)contactInfoChanged:(NSNotification *)notification {
    ATContactStorage *contact = [ATContactStorage sharedContactStorage];
    if (contact.name) {
        feedback.name = contact.name;
    }
    if (contact.phone) {
        feedback.phone = contact.phone;
    }
    if (contact.email) {
        feedback.email = contact.email;
    }
}

- (void)screenshotChanged:(NSNotification *)notification {
	if (self.feedback.screenshot) {
        self.feedback.screenshotSwitchEnabled = YES;
		[self updateThumbnail];
	} 
}

- (void)captureFeedbackState {
    self.feedback.text = self.feedbackView.text;
	self.feedback.email = self.emailField.text;
}


- (void)hide:(BOOL)animated {
	[self retain];
	
	self.window.windowLevel = UIWindowLevelNormal;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	if (animated) {
		[UIView beginAnimations:@"windowHide" context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		self.window.alpha = 0.0;
		[UIView commitAnimations];
	} else {
		[self finishHide];
	}
}

- (void)finishHide {
	self.window.alpha = 0.0;
	self.window.hidden = YES;
	[self.window removeFromSuperview];
}

- (void)finishUnhide {
	[self updateThumbnail];
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


- (CGRect)photoControlFrame {
	if ([self shouldShowThumbnail] && [self shouldShowPaperclip]) {
		return photoFrameView.frame;
	} else {
		CGRect f = paperclipView.frame;
		f.size.height += 10;
		return f;
	}
}

- (CGFloat)attachmentVerticalOffset {
	return self.toolbar.bounds.size.height - 4.0;
}

- (void)updateThumbnail {
	@synchronized(self) {
		if ([self shouldShowPaperclip]) {
			UIImage *image = feedback.screenshot;
			UIImageView *thumbnailView = (UIImageView *)[self.view viewWithTag:kFeedbackPhotoPreviewTag];
			
			CGRect paperclipBackgroundFrame = paperclipBackgroundView.frame;
			paperclipBackgroundFrame.origin.y = [self attachmentVerticalOffset] + 6.0;
			paperclipBackgroundView.frame = paperclipBackgroundFrame;
			
			CGRect paperclipFrame = paperclipView.frame;
			paperclipFrame.origin.y = [self attachmentVerticalOffset];
			paperclipView.frame = paperclipFrame;
			
			if (image == nil) {
				[currentImage release], currentImage = nil;
				
				if (thumbnailView != nil) {
					[thumbnailView removeFromSuperview];
					[thumbnailView release], thumbnailView = nil;
				}
				if (photoFrameView != nil) {
					[photoFrameView removeFromSuperview];
					[photoFrameView release], photoFrameView = nil;
				}
				photoControl.frame = [self photoControlFrame];
				photoControl.transform = paperclipView.transform;
			} else {
				if (photoFrameView == nil) {
					CGRect viewBounds = self.view.bounds;
					UIImage *photoFrame = [ATBackend imageNamed:@"at_photo"];
					photoFrameView = [[UIImageView alloc] initWithImage:photoFrame];
					photoFrameView.frame = CGRectMake(viewBounds.size.width - photoFrame.size.width - 2.0, [self attachmentVerticalOffset], photoFrame.size.width, photoFrame.size.height);
					[self.view addSubview:photoFrameView];
					photoFrameView.tag = kFeedbackPhotoFrameTag;
					photoFrameView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
				}
				CGRect photoFrameFrame = photoFrameView.frame;
				photoFrameFrame.origin.y = [self attachmentVerticalOffset];
				photoFrameView.frame = photoFrameFrame;
				
				if (thumbnailView == nil) {
					thumbnailView = [[[UIImageView alloc] init] autorelease];
					thumbnailView.tag = kFeedbackPhotoPreviewTag;
					thumbnailView.contentMode = UIViewContentModeTop;
					thumbnailView.clipsToBounds = YES;
					thumbnailView.backgroundColor = [UIColor blackColor];
					[self.view addSubview:thumbnailView];
					[self.view bringSubviewToFront:paperclipBackgroundView];
					[self.view bringSubviewToFront:thumbnailView];
					[self.view bringSubviewToFront:photoFrameView];
					[self.view bringSubviewToFront:paperclipView];
					[self.view bringSubviewToFront:photoControl];
					
					thumbnailView.transform = CGAffineTransformMakeRotation(DEG_TO_RAD(3.5));
				}
				
				photoFrameView.alpha = 1.0;
				CGFloat scale = [[UIScreen mainScreen] scale];
				
				if (![image isEqual:currentImage]) {
					[currentImage release], currentImage = nil;
					currentImage = [image retain];
					CGSize imageSize = image.size;
					CGSize scaledImageSize = imageSize;
					CGFloat fitDimension = 70.0 * scale;
					
					if (imageSize.width > imageSize.height) {
						scaledImageSize.height = fitDimension;
						scaledImageSize.width = (fitDimension/imageSize.height) * imageSize.width;
					} else {
						scaledImageSize.height = (fitDimension/imageSize.width) * imageSize.height;
						scaledImageSize.width = fitDimension;
					}
					UIImage *scaledImage = [ATUtilities imageByScalingImage:image toSize:scaledImageSize scale:scale fromITouchCamera:feedback.imageIsFromCamera];
					thumbnailView.image = scaledImage;
				}
				CGRect f = CGRectMake(11.5, 11.5, 70, 70);
				f = CGRectOffset(f, photoFrameView.frame.origin.x, photoFrameView.frame.origin.y);
				thumbnailView.frame = f;
				thumbnailView.bounds = CGRectMake(0.0, 0.0, 70.0, 70.0);
				photoControl.frame = [self photoControlFrame];
				photoControl.transform = photoFrameView.transform;
			}
			
		}
	}
}

- (void)sendFeedbackAndDismiss {
    [[ATBackend sharedBackend] sendFeedback:self.feedback];
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:parentWindow];
    hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting feedback.");
    [hud show];
    [hud autorelease];
	[self dismiss:YES];
}

- (void)updateSendButtonState {
	BOOL empty = [@"" isEqualToString:self.feedbackView.text];
	self.doneButton.enabled = !empty;
	self.doneButton.style = empty == YES ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone;
}
@end


@implementation ATFeedbackController (Positioning)
- (CGRect)onscreenRectOfView {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat w = statusBarSize.width;
	CGFloat h = statusBarSize.height;
	CGFloat topPadding = 0.0;
	if (CGSizeEqualToSize(CGSizeZero, statusBarSize)) {
		w = screenBounds.size.width;
		h = screenBounds.size.height;
	}
	
	BOOL isLandscape = NO;
	
	CGFloat windowWidth = 0.0;
	
    switch (orientation) { 
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
			isLandscape = YES;
			topPadding = statusBarSize.width;
			windowWidth = h;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
		case UIInterfaceOrientationPortrait:
		default:
			topPadding = statusBarSize.height;
			windowWidth = w;
            break;
    }
	
	CGFloat viewHeight = 0.0;
	CGFloat viewWidth = 0.0;
	CGFloat originY = 0.0;
	CGFloat originX = 0.0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		viewHeight = isLandscape ? 368.0 : 368.0;
		originY = isLandscape ? 20.0 : 200;
		//viewWidth = isLandscape ? 200.0 : 300.0;
		viewWidth = windowWidth - 12*2 - 100.0;
		originX = floorf((windowWidth - viewWidth)/2.0);
	} else {
		viewHeight = isLandscape ? 188.0 : 258.0;
		viewHeight -= topPadding;
		viewWidth = windowWidth - 12;
		originX = 6.0;
	}
	
	CGRect f = self.view.frame;
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
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
    CGFloat angle = 0.0;
    CGRect newFrame = [self windowForViewController:presentingViewController].bounds;
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
	UIView *containerView = [self.view viewWithTag:kContainerViewTag];
	if (containerView != nil) {
		CGRect containerFrame = containerView.frame;
		containerFrame.origin.y = toolbarBounds.size.height;
		containerFrame.size.height = self.view.bounds.size.height - toolbarBounds.size.height;
		containerView.frame = containerFrame;
	}
	
    self.window.transform = CGAffineTransformMakeRotation(angle);
    self.window.frame = newFrame;
	CGRect onscreenRect = [self onscreenRectOfView];
	CGFloat viewWidth = onscreenRect.size.width;
	self.view.frame = onscreenRect;
	
	CGRect feedbackViewFrame = self.feedbackView.frame;
	feedbackViewFrame.origin.x = 0.0;
	if ([self shouldShowPaperclip] && [self shouldShowThumbnail]) {
		feedbackViewFrame.size.width = viewWidth - 100;
		self.feedbackView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, -100.0);
	} else {
		feedbackViewFrame.size.width = viewWidth;
		self.feedbackView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
	}
	self.feedbackView.frame = feedbackViewFrame;
	
	[self updateThumbnail];
}
@end
