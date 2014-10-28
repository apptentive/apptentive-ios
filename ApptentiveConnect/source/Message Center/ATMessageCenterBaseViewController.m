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
- (void)showSendImageUIIfNecessary;
- (CGRect)formRectToShow;
- (void)registerForKeyboardNotifications;
- (void)keyboardWillBeShown:(NSNotification *)aNotification;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
@end

@implementation ATMessageCenterBaseViewController {
	BOOL attachmentsVisible;
	CGRect currentKeyboardFrameInView;
	CGFloat composerFieldHeight;
	BOOL animatingTransition;
	
	ATDefaultMessageCenterTheme *defaultTheme;
	
	ATTextMessage *composingMessage;
	BOOL showAttachSheetOnBecomingVisible;
	UIImage *pickedImage;
	UIActionSheet *sendImageActionSheet;
	ATFeedbackImageSource pickedImageSource;
	ATAbstractMessage *retryMessage;
	UIActionSheet *retryMessageActionSheet;
	
	UINib *inputViewNib;
	ATMessageInputView *inputView;
	
	ATMessageCenterDataSource *dataSource;
}
@synthesize containerView, inputContainerView, dismissalDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		defaultTheme = [[ATDefaultMessageCenterTheme alloc] init];
		dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
    }
    return self;
}

- (void)dealloc {
	inputView.delegate = nil;
	dataSource.delegate = nil;
	[dataSource release], dataSource = nil;
	dismissalDelegate = nil;
	[pickedImage release], pickedImage = nil;
	[defaultTheme release], defaultTheme = nil;
	[containerView release], containerView = nil;
	[inputContainerView release], containerView = nil;
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[dataSource start];
	
	if ([[ATConnect sharedConnection] tintColor] && [self.view respondsToSelector:@selector(setTintColor:)]) {
		[self.navigationController.view setTintColor:[[ATConnect sharedConnection] tintColor]];
	}
	
	self.navigationItem.titleView = [defaultTheme titleViewForMessageCenterViewController:self];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];
	if ([self.navigationItem.leftBarButtonItem respondsToSelector:@selector(initWithImage:landscapeImagePhone:style:target:action:)]) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] landscapeImagePhone:[ATBackend imageNamed:@"at_user_button_image_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)]autorelease];
		self.navigationItem.rightBarButtonItem.accessibilityLabel = ATLocalizedString(@"Contact Settings", @"Title of contact information edit screen");
	} else {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)]autorelease];
	}
		
	[self.view addSubview:self.containerView];
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		inputViewNib = [UINib nibWithNibName:@"ATMessageInputViewV7" bundle:[ATConnect resourceBundle]];
	} else {
		inputViewNib = [UINib nibWithNibName:@"ATMessageInputView" bundle:[ATConnect resourceBundle]];
	}
	NSArray *views = [inputViewNib instantiateWithOwner:self options:NULL];
	if ([views count] == 0) {
		ATLogError(@"Unable to load message input view.");
	} else {
		inputView = [views objectAtIndex:0];
		CGRect inputContainerFrame = self.inputContainerView.frame;
		[inputContainerView removeFromSuperview];
		self.inputContainerView = nil;
		[self.view addSubview:inputView];
		inputView.frame = inputContainerFrame;
		inputView.delegate = self;
		self.inputContainerView = inputView;
	}
	
	[defaultTheme configureSendButton:inputView.sendButton forMessageCenterViewController:self];
	[defaultTheme configureAttachmentsButton:inputView.attachButton forMessageCenterViewController:self];
	inputView.backgroundImage = [defaultTheme backgroundImageForMessageForMessageCenterViewController:self];
	
	inputView.placeholder = ATLocalizedString(@"Type a message…", @"Placeholder for message center text input.");
	
	[self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[dataSource markAllMessagesAsRead];
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
	if (showAttachSheetOnBecomingVisible) {
		showAttachSheetOnBecomingVisible = NO;
		if (sendImageActionSheet) {
			[sendImageActionSheet autorelease], sendImageActionSheet = nil;
		}
		sendImageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Image", @"Send image button title"), nil];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[sendImageActionSheet showFromRect:inputView.sendButton.bounds inView:inputView.sendButton animated:YES];
		} else {
			[sendImageActionSheet showInView:self.view];
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
	[vc release], vc = nil;
}

- (IBAction)cameraPressed:(id)sender {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:nc animated:YES completion:^{}];
	[vc release], vc = nil;
	[nc release], nc = nil;
}

- (ATMessageCenterDataSource *)dataSource {
	return dataSource;
}

- (void)showRetryMessageActionSheetWithMessage:(ATAbstractMessage *)message {
	if (retryMessageActionSheet) {
		[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
	}
	if (retryMessage) {
		[retryMessage release], retryMessage = nil;
	}
	retryMessage = [message retain];
	NSArray *errors = [message errorsFromErrorMessage];
	NSString *errorString = nil;
	if (errors != nil && [errors count] != 0) {
		errorString = [NSString stringWithFormat:ATLocalizedString(@"Error Sending Message: %@", @"Title of action sheet for messages with errors. Parameter is the error."), [errors componentsJoinedByString:@"\n"]];
	} else {
		errorString = ATLocalizedString(@"Error Sending Message", @"Title of action sheet for messages with errors, but no error details.");
	}
	retryMessageActionSheet = [[UIActionSheet alloc] initWithTitle:errorString delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Retry Sending", @"Retry sending message title"), nil];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[retryMessageActionSheet showFromRect:inputView.sendButton.bounds inView:inputView.sendButton animated:YES];
	} else {
		[retryMessageActionSheet showInView:self.view];
	}
}

- (void)showLongMessageControllerWithMessage:(ATTextMessage *)message {
	ATLongMessageViewController *vc = [[ATLongMessageViewController alloc] initWithNibName:@"ATLongMessageViewController" bundle:[ATConnect resourceBundle]];
	[vc setText:message.body];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (void)relayoutSubviews {
	
}

- (void)scrollToBottom {
	
}

- (CGRect)currentKeyboardFrameInView {
	return currentKeyboardFrameInView;
}

#pragma mark ATMessageInputViewDelegate
- (void)messageInputViewDidChange:(ATMessageInputView *)anInputView {
	if (anInputView.text && ![anInputView.text isEqualToString:@""]) {
		if (!composingMessage) {
			composingMessage = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
			ATConversation *conversation = [ATConversationUpdater currentConversation];
			if (conversation) {
				ATMessageSender *sender = [ATMessageSender findSenderWithID:conversation.personID];
				if (sender) {
					composingMessage.sender = sender;
				}
			}
			[composingMessage setup];
			composingMessage.sentByUser = @YES;
			composingMessage.seenByUser = @YES;
		}
	} else {
		if (composingMessage) {
			NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
			[context deleteObject:composingMessage];
			[composingMessage release], composingMessage = nil;
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
		if (composingMessage == nil) {
			composingMessage = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
			[composingMessage setup];
		}
		composingMessage.body = [inputView text];
		composingMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
		composingMessage.sentByUser = @YES;
		composingMessage.seenByUser = @YES;
		if ([ATBackend sharedBackend].currentCustomData) {
			[composingMessage addCustomDataFromDictionary:[ATBackend sharedBackend].currentCustomData];
		}
		[composingMessage updateClientCreationTime];
		
		[[[ATBackend sharedBackend] managedObjectContext] save:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidSendNotification object:@{ATMessageCenterMessageNonceKey:composingMessage.pendingMessageID}];
		
		// Give it a wee bit o' delay.
		NSString *pendingMessageID = [composingMessage pendingMessageID];
		double delayInSeconds = 1.5;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			ATMessageTask *task = [[ATMessageTask alloc] init];
			task.pendingMessageID = pendingMessageID;
			[[ATTaskQueue sharedTaskQueue] addTask:task];
			[[ATTaskQueue sharedTaskQueue] start];
			[task release], task = nil;
		});
		[composingMessage release], composingMessage = nil;
		inputView.text = @"";
	}
	
}

- (void)messageInputViewAttachPressed:(ATMessageInputView *)anInputView {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:nc animated:YES completion:^{}];
	[vc release], vc = nil;
	[nc release], nc = nil;
}

#pragma mark ATSimpleImageViewControllerDelegate
- (void)imageViewControllerVoidedDefaultImage:(ATSimpleImageViewController *)vc {
	if (pickedImage) {
		[pickedImage release], pickedImage = nil;
	}
}

- (void)imageViewController:(ATSimpleImageViewController *)vc pickedImage:(UIImage *)image fromSource:(ATFeedbackImageSource)source {
	if (pickedImage != image) {
		[pickedImage release], pickedImage = nil;
		pickedImage = [image retain];
		pickedImageSource = source;
	}
}

- (void)imageViewControllerWillDismiss:(ATSimpleImageViewController *)vc animated:(BOOL)animated {
	if (pickedImage) {
		showAttachSheetOnBecomingVisible = YES;
	}
}

- (void)imageViewControllerDidDismiss:(ATSimpleImageViewController *)vc {
	[self showSendImageUIIfNecessary];
}

- (ATFeedbackAttachmentOptions)attachmentOptionsForImageViewController:(ATSimpleImageViewController *)vc {
	return ATFeedbackAllowPhotoAttachment | ATFeedbackAllowTakePhotoAttachment;
}

- (UIImage *)defaultImageForImageViewController:(ATSimpleImageViewController *)vc {
	return pickedImage;
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
	attachmentsVisible = NO;
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.view.window convertRect:kbFrame toView:self.view];
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self relayoutSubviews];
			[self scrollToBottom];
		}];
	} else {
		currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
	}
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	[self scrollToBottom];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectZero;
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self relayoutSubviews];
			[self scrollToBottom];
		}];
	} else {
		currentKeyboardFrameInView = CGRectZero;
	}
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet == sendImageActionSheet) {
		if (buttonIndex == 0) {
			if (pickedImage) {
				[[ATBackend sharedBackend] sendImageMessageWithImage:pickedImage fromSource:pickedImageSource];
				[pickedImage release], pickedImage = nil;
			}
		} else if (buttonIndex == 1) {
			[pickedImage release], pickedImage = nil;
		}
		[sendImageActionSheet autorelease], sendImageActionSheet = nil;
	} else if (actionSheet == retryMessageActionSheet) {
		if (buttonIndex == 0) {
			retryMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
			[[[ATBackend sharedBackend] managedObjectContext] save:nil];
			
			// Give it a wee bit o' delay.
			NSString *pendingMessageID = [retryMessage pendingMessageID];
			double delayInSeconds = 1.5;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				ATMessageTask *task = [[ATMessageTask alloc] init];
				task.pendingMessageID = pendingMessageID;
				[[ATTaskQueue sharedTaskQueue] addTask:task];
				[[ATTaskQueue sharedTaskQueue] start];
				[task release], task = nil;
			});
			
			[retryMessage release], retryMessage = nil;
		} else if (buttonIndex == 1) {
			[ATData deleteManagedObject:retryMessage];
			[retryMessage release], retryMessage = nil;
		}
		[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
	if (actionSheet == sendImageActionSheet) {
		if (pickedImage) {
			[pickedImage release], pickedImage = nil;
		}
		[sendImageActionSheet autorelease], sendImageActionSheet = nil;
	} else if (actionSheet == retryMessageActionSheet) {
		[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
	}
}
@end
