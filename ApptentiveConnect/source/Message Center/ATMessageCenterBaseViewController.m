//
//  ATMessageCenterBaseViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterBaseViewController.h"

#import "ATAbstractMessage.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATDefaultMessageCenterTheme.h"
#import "ATFileMessage.h"
#import "ATLog.h"
#import "ATLongMessageViewController.h"
#import "ATMessageCenterDataSource.h"
#import "ATMessageCenterMetrics.h"
#import "ATMessageSender.h"
#import "ATMessageTask.h"
#import "ATPersonDetailsViewController.h"
#import "ATTaskQueue.h"
#import "ATTextMessage.h"
#import "ATUtilities.h"

@interface ATMessageCenterBaseViewController ()

@property (assign, nonatomic) BOOL attachmentsVisible;
@property (assign, nonatomic) CGRect currentKeyboardFrameInView;
@property (assign, nonatomic) CGFloat composerFieldHeight;
@property (assign, nonatomic) BOOL animatingTransition;

@property (strong, nonatomic) ATDefaultMessageCenterTheme *defaultTheme;

@property (strong, nonatomic) ATTextMessage *composingMessage;
@property (assign, nonatomic) BOOL showAttachSheetOnBecomingVisible;
@property (strong, nonatomic) UIImage *pickedImage;
@property (strong, nonatomic) UIActionSheet *sendImageActionSheet;
@property (assign, nonatomic) ATFeedbackImageSource pickedImageSource;
@property (strong, nonatomic) ATAbstractMessage *retryMessage;
@property (strong, nonatomic) UIActionSheet *retryMessageActionSheet;

@property (strong, nonatomic) UINib *inputViewNib;
@property (strong, nonatomic) ATMessageInputView *inputView;

@property (strong, nonatomic) ATMessageCenterDataSource *dataSource;

- (void)showSendImageUIIfNecessary;
- (CGRect)formRectToShow;
- (void)registerForKeyboardNotifications;
- (void)keyboardWillBeShown:(NSNotification *)aNotification;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
@end

@implementation ATMessageCenterBaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_defaultTheme = [[ATDefaultMessageCenterTheme alloc] init];
		_dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.dataSource start];
	
	if ([[ATConnect sharedConnection] tintColor] && [self.view respondsToSelector:@selector(setTintColor:)]) {
		[self.navigationController.view setTintColor:[[ATConnect sharedConnection] tintColor]];
	}
	
	self.navigationItem.titleView = [self.defaultTheme titleViewForMessageCenterViewController:self];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
	if ([self.navigationItem.leftBarButtonItem respondsToSelector:@selector(initWithImage:landscapeImagePhone:style:target:action:)]) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] landscapeImagePhone:[ATBackend imageNamed:@"at_user_button_image_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
		self.navigationItem.rightBarButtonItem.accessibilityLabel = ATLocalizedString(@"Contact Settings", @"Title of contact information edit screen");
	} else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
	}
		
	[self.view addSubview:self.containerView];
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		self.inputViewNib = [UINib nibWithNibName:@"ATMessageInputViewV7" bundle:[ATConnect resourceBundle]];
	} else {
		self.inputViewNib = [UINib nibWithNibName:@"ATMessageInputView" bundle:[ATConnect resourceBundle]];
	}
	NSArray *views = [self.inputViewNib instantiateWithOwner:self options:NULL];
	if ([views count] == 0) {
		ATLogError(@"Unable to load message input view.");
	} else {
		self.inputView = [views objectAtIndex:0];
		CGRect inputContainerFrame = self.inputContainerView.frame;
		[self.inputContainerView removeFromSuperview];
		self.inputContainerView = nil;
		[self.view addSubview:self.inputView];
		self.inputView.frame = inputContainerFrame;
		self.inputView.delegate = self;
		self.inputContainerView = self.inputView;
	}
	
	[self.defaultTheme configureSendButton:self.inputView.sendButton forMessageCenterViewController:self];
	[self.defaultTheme configureAttachmentsButton:self.inputView.attachButton forMessageCenterViewController:self];
	self.inputView.backgroundImage = [self.defaultTheme backgroundImageForMessageForMessageCenterViewController:self];
	
	self.inputView.placeholder = ATLocalizedString(@"Type a message…", @"Placeholder for message center text input.");
	
	[self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.dataSource markAllMessagesAsRead];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self showSendImageUIIfNecessary];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidHideNotification object:nil];
	if (self.dismissalDelegate && [self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
		[self.dismissalDelegate messageCenterDidDismiss:self];
	}
}

- (void)showSendImageUIIfNecessary {
	if (self.showAttachSheetOnBecomingVisible) {
		self.showAttachSheetOnBecomingVisible = NO;
		if (self.sendImageActionSheet) {
			self.sendImageActionSheet = nil;
		}
		self.sendImageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Image", @"Send image button title"), nil];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[self.sendImageActionSheet showFromRect:self.inputView.sendButton.bounds inView:self.inputView.sendButton animated:YES];
		} else {
			[self.sendImageActionSheet showInView:self.view];
		}
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}

- (IBAction)donePressed:(id)sender {
	if (self.dismissalDelegate) {
		[self.dismissalDelegate messageCenterWillDismiss:self];
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)settingsPressed:(id)sender {
	ATPersonDetailsViewController *vc = [[ATPersonDetailsViewController alloc] initWithNibName:@"ATPersonDetailsViewController" bundle:[ATConnect resourceBundle]];
	[self.navigationController pushViewController:vc animated:YES];
	vc = nil;
}

- (IBAction)cameraPressed:(id)sender {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:nc animated:YES completion:^{}];
	vc = nil;
	nc = nil;
}

- (ATMessageCenterDataSource *)dataSource {
	return _dataSource;
}

- (void)showRetryMessageActionSheetWithMessage:(ATAbstractMessage *)message {
	if (self.retryMessageActionSheet) {
		self.retryMessageActionSheet = nil;
	}
	if (self.retryMessage) {
		self.retryMessage = nil;
	}
	self.retryMessage = message;
	NSArray *errors = [message errorsFromErrorMessage];
	NSString *errorString = nil;
	if (errors != nil && [errors count] != 0) {
		errorString = [NSString stringWithFormat:ATLocalizedString(@"Error Sending Message: %@", @"Title of action sheet for messages with errors. Parameter is the error."), [errors componentsJoinedByString:@"\n"]];
	} else {
		errorString = ATLocalizedString(@"Error Sending Message", @"Title of action sheet for messages with errors, but no error details.");
	}
	self.retryMessageActionSheet = [[UIActionSheet alloc] initWithTitle:errorString delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Retry Sending", @"Retry sending message title"), nil];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[self.retryMessageActionSheet showFromRect:self.inputView.sendButton.bounds inView:self.inputView.sendButton animated:YES];
	} else {
		[self.retryMessageActionSheet showInView:self.view];
	}
}

- (void)showLongMessageControllerWithMessage:(ATTextMessage *)message {
	ATLongMessageViewController *vc = [[ATLongMessageViewController alloc] initWithNibName:@"ATLongMessageViewController" bundle:[ATConnect resourceBundle]];
	[vc setText:message.body];
	[self.navigationController pushViewController:vc animated:YES];
	vc = nil;
}

- (void)relayoutSubviews {
	
}

- (void)scrollToBottom {
	
}

- (CGRect)currentKeyboardFrameInView {
	return _currentKeyboardFrameInView;
}

#pragma mark ATMessageInputViewDelegate
- (void)messageInputViewDidChange:(ATMessageInputView *)anInputView {
	if (anInputView.text && ![anInputView.text isEqualToString:@""]) {
		if (!self.composingMessage) {
			self.composingMessage = [[ATBackend sharedBackend] createTextMessageWithBody:nil hiddenOnClient:NO];
		}
	} else {
		if (self.composingMessage) {
			NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
			[context deleteObject:self.composingMessage];
			self.composingMessage = nil;
		}
	}
	[self relayoutSubviews];
}

- (void)messageInputView:(ATMessageInputView *)anInputView didChangeHeight:(CGFloat)height {
	[self relayoutSubviews];
	[self scrollToBottom];
}

- (void)messageInputViewSendPressed:(ATMessageInputView *)anInputView {
	@synchronized(self) {
		if (self.composingMessage == nil) {
			self.composingMessage = [[ATBackend sharedBackend] createTextMessageWithBody:self.inputView.text hiddenOnClient:NO];
		} else {
			self.composingMessage.body = self.inputView.text;
		}

		[[ATBackend sharedBackend] sendTextMessage:self.composingMessage completion:^(NSString *pendingMessageID){
			self.composingMessage = nil;
		}];
		self.inputView.text = @"";
	}
}

- (void)messageInputViewAttachPressed:(ATMessageInputView *)anInputView {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:nc animated:YES completion:^{}];
	vc = nil;
	nc = nil;
}

#pragma mark ATSimpleImageViewControllerDelegate
- (void)imageViewControllerVoidedDefaultImage:(ATSimpleImageViewController *)vc {
	if (self.pickedImage) {
		self.pickedImage = nil;
	}
}

- (void)imageViewController:(ATSimpleImageViewController *)vc pickedImage:(UIImage *)image fromSource:(ATFeedbackImageSource)source {
	if (self.pickedImage != image) {
		self.pickedImage = nil;
		self.pickedImage = image;
		self.pickedImageSource = source;
	}
}

- (void)imageViewControllerWillDismiss:(ATSimpleImageViewController *)vc animated:(BOOL)animated {
	if (self.pickedImage) {
		self.showAttachSheetOnBecomingVisible = YES;
	}
}

- (void)imageViewControllerDidDismiss:(ATSimpleImageViewController *)vc {
	[self showSendImageUIIfNecessary];
}

- (ATFeedbackAttachmentOptions)attachmentOptionsForImageViewController:(ATSimpleImageViewController *)vc {
	return ATFeedbackAllowPhotoAttachment | ATFeedbackAllowTakePhotoAttachment;
}

- (UIImage *)defaultImageForImageViewController:(ATSimpleImageViewController *)vc {
	return self.pickedImage;
}

#pragma mark Keyboard Handling
- (CGRect)formRectToShow {
	CGRect result = self.inputContainerView.frame;
	return result;
}

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillBeShown:(NSNotification *)aNotification {
	self.attachmentsVisible = NO;
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.view.window convertRect:kbFrame toView:self.view];
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!self.animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			self.animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			self.currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			self.animatingTransition = NO;
			[self relayoutSubviews];
			[self scrollToBottom];
		}];
	} else {
		self.currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
	}
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	[self scrollToBottom];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!self.animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			self.animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			self.currentKeyboardFrameInView = CGRectZero;
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			self.animatingTransition = NO;
			[self relayoutSubviews];
			[self scrollToBottom];
		}];
	} else {
		self.currentKeyboardFrameInView = CGRectZero;
	}
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet == self.sendImageActionSheet) {
		if (buttonIndex == 0) {
			if (self.pickedImage) {
				[[ATBackend sharedBackend] sendImageMessageWithImage:self.pickedImage fromSource:self.pickedImageSource];
				self.pickedImage = nil;
			}
		} else if (buttonIndex == 1) {
			self.pickedImage = nil;
		}
		self.sendImageActionSheet = nil;
	} else if (actionSheet == self.retryMessageActionSheet) {
		if (buttonIndex == 0) {
			self.retryMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
			[[[ATBackend sharedBackend] managedObjectContext] save:nil];
			
			// Give it a wee bit o' delay.
			NSString *pendingMessageID = [self.retryMessage pendingMessageID];
			double delayInSeconds = 1.5;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				ATMessageTask *task = [[ATMessageTask alloc] init];
				task.pendingMessageID = pendingMessageID;
				[[ATTaskQueue sharedTaskQueue] addTask:task];
				[[ATTaskQueue sharedTaskQueue] start];
			});
			
			self.retryMessage = nil;
		} else if (buttonIndex == 1) {
			[ATData deleteManagedObject:self.retryMessage];
			self.retryMessage = nil;
		}
		self.retryMessageActionSheet = nil;
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
	if (actionSheet == self.sendImageActionSheet) {
		if (self.pickedImage) {
			self.pickedImage = nil;
		}
		self.sendImageActionSheet = nil;
	} else if (actionSheet == self.retryMessageActionSheet) {
		self.retryMessageActionSheet = nil;
	}
}
@end
