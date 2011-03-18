//
//  ATContactInfoController.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATContactInfoController.h"
#import <QuartzCore/QuartzCore.h>
#import "ATConnect.h"
#import "ATFeedback.h"

@interface ATContactInfoController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)setupFeedback;
- (void)teardown;
@end

@implementation ATContactInfoController
@synthesize feedback, screenshotView;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATContactInfoController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATContactInfoController_iPad" bundle:[ATConnect resourceBundle]];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setScreenshotView:(UIImageView *)newScreenshotView {
    if (screenshotView != newScreenshotView) {
        [screenshotView release];
        screenshotView = nil;
        screenshotView = [newScreenshotView retain];
        screenshotView.image = feedback.screenshot;
    }
}

- (void)setFeedback:(ATFeedback *)newFeedback {
    if (feedback != newFeedback) {
        [feedback removeObserver:self forKeyPath:@"screenshot"];
        [feedback release];
        feedback = nil;
        feedback = [newFeedback retain];
        screenshotView.image = feedback.screenshot;
        [feedback addObserver:self forKeyPath:@"screenshot" options:0 context:NULL];
        [self setupFeedback];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == feedback) {
        screenshotView.image = feedback.screenshot;
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [emailField becomeFirstResponder];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (IBAction)nextStep:(id)sender {
    feedback.email = emailField.text;
    feedback.phone = phoneField.text;
    if (!screenshotSwitch.on) {
        feedback.screenshot = nil;
    }
    //TODO
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)screenshotSwitchToggled:(id)sender {
    [UIView beginAnimations:@"screenshotSwitch" context:NULL];
    [UIView setAnimationDuration:0.4];
    screenshotView.alpha = screenshotSwitch.on ? 1.0 : 0.0;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:@"imageViewToBack"]) {
        [imageControl removeFromSuperview];
        [self.view addSubview:imageControl];
        imageControl.frame = screenshotFrame;
    }
}

- (IBAction)imageControlTapped:(id)sender {
    if ([emailField isEditing]) {
        [emailField resignFirstResponder];
    } else if ([phoneField isEditing]) {
        [phoneField resignFirstResponder];
    }
    [self.view bringSubviewToFront:screenshotView];
    [self.view bringSubviewToFront:imageControl];
    
    if (previewingImage) {
        previewingImage = NO;
        
        UIWindow *window = self.view.window;
        CGRect targetFrame = [window convertRect:screenshotFrame fromView:self.view];
        
        [UIView beginAnimations:@"imageViewToBack" context:NULL];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        imageControl.frame = targetFrame;
        imageControl.layer.shadowRadius = 0.0;
        imageControl.layer.shadowOpacity = 0.0;
        [UIView commitAnimations];
    } else {
        previewingImage = YES;
        screenshotFrame = [imageControl frame];
        
        // Move screenshot from our view to the window.
        UIWindow *window = self.view.window;
        CGRect newOriginatingFrame = [self.view convertRect:imageControl.frame toView:window];
        [imageControl removeFromSuperview];
        [window addSubview:imageControl];
        imageControl.frame = newOriginatingFrame;
        
        [UIView beginAnimations:@"imageViewToFront" context:NULL];
        [UIView setAnimationDuration:0.3];
        imageControl.layer.shadowRadius = 40.0;
        imageControl.layer.shadowColor = [UIColor blackColor].CGColor;
        imageControl.layer.shadowOpacity = 0.5;
        CGSize newSize = CGSizeMake(floor(feedback.screenshot.size.width * 0.8), floor(feedback.screenshot.size.height * 0.8));
        CGSize diff = CGSizeMake(floor((imageControl.superview.frame.size.width - newSize.width)/2.0), floor((imageControl.superview.frame.size.height - newSize.height)/2.0));
        CGRect newFrame = CGRectMake(diff.width, diff.height, newSize.width, newSize.height);
        imageControl.frame = newFrame;
        [UIView commitAnimations];
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end

@implementation ATContactInfoController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == emailField) {
        [phoneField becomeFirstResponder];
        return NO;
    } else if (view == phoneField) {
        [phoneField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)setup {
    self.title = NSLocalizedString(@"Info", nil);
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStyleDone target:self action:@selector(nextStep:)] autorelease];
    [imageControl setUserInteractionEnabled:YES];
    [imageControl setEnabled:YES];
    [self setupFeedback];
}

- (void)setupFeedback {
    if (emailField && (!emailField.text || [@"" isEqualToString:emailField.text]) && feedback.email) {
        emailField.text = feedback.email;
    }
    if (phoneField && (!phoneField.text || [@"" isEqualToString:phoneField.text]) && feedback.phone) {
        phoneField.text = feedback.phone;
    }
}

- (void)teardown {
    self.feedback = nil;
    [emailField release];
    emailField = nil;
    [phoneField release];
    phoneField = nil;
    [screenshotView release];
    screenshotView = nil;
    [screenshotSwitch release];
    screenshotSwitch = nil;
    [imageControl release];
    imageControl = nil;
}
@end
