//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterViewController.h"
#import "ATMessageCenterGreetingView.h"
#import "ATMessageCenterConfirmationView.h"
#import "ATMessageCenterMessageCell.h"
#import "ATMessageCenterReplyCell.h"
#import "ATBackend.h"
#import "ATMessageCenterInteraction.h"

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ATMessageCenterGreetingView *greetingView;
@property (weak, nonatomic) IBOutlet ATMessageCenterConfirmationView *confirmationView;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextView *messageView;
@property (nonatomic, readwrite, retain) IBOutlet UIView *inputAccessoryView;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self updateHeaderHeightForOrientation:self.interfaceOrientation];
	
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedRowHeight = 44.0;

	self.navigationItem.title = self.interaction.title;
	
	self.inputAccessoryView.layer.borderColor = [[UIColor colorWithRed:215/255.0f green:219/255.0f blue:223/255.0f alpha:1.0f] CGColor];
	self.inputAccessoryView.layer.borderWidth = 0.5;
	
	// DEBUG
	self.greetingView.imageView.image = [UIImage imageNamed:@"ApptentiveResources.bundle/Sumo.jpg"];
	// /DEBUG
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	[UIView animateWithDuration:duration animations:^{
//		[self.tableView reloadData];
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
	}];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
//	[self becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // TODO: Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO: Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section % 2 == 0) {
		ATMessageCenterMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
		return cell;
	} else {
		ATMessageCenterReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		// DEBUG
		cell.supportUserImageView.image = [UIImage imageNamed:@"ApptentiveResources.bundle/Sumo.jpg"];
		cell.replyLabel.text = @"Hey Andrew. I can help you with that. We’ve had a couple reports of this happening on older versions of the app.\n\nIf you open the App Store, and click the “Updates” tab, you should see that our latest version is 4.3.5. From there, you can tap “Update All” - many customers report this helping them.\n\nIn the mean time, could you please describe what it was that caused the bug in the first place? What part of the app were you in, what did you tap, and what were you trying to accomplish?";
		// /DEBUG
		
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"cell: %@", cell);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 4.0;
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
	[self.dismissalDelegate messageCenterWillDismiss:self];
	
	[self dismissViewControllerAnimated:YES completion:^{
		if ([self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
			[self.dismissalDelegate messageCenterDidDismiss:self];
		}
	}];
}

- (IBAction)sendButtonPressed:(id)sender {
	NSString *message = self.messageView.text;
	
	if (message && ![message isEqualToString:@""]) {
		[[ATBackend sharedBackend] sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {}];
		
		self.messageView.text = @"";
	}
}

- (IBAction)tableViewTapped:(id)sender {
	[self.messageView resignFirstResponder];
}

#pragma mark - Private

- (void)updateHeaderHeightForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 128.0 : 280.0;

	self.greetingView.bounds = CGRectMake(0, 0, self.tableView.bounds.size.height, headerHeight);
	[self.greetingView updateConstraints];
	self.tableView.tableHeaderView = self.greetingView;
}

@end
