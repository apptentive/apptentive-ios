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
#import "ATConnect_Private.h"
#import "ATNetworkImageView.h"

NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ATMessageCenterGreetingView *greetingView;
@property (weak, nonatomic) IBOutlet ATMessageCenterConfirmationView *confirmationView;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextView *messageView;
@property (nonatomic, readwrite, retain) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMdjm" options:0 locale:[NSLocale currentLocale]];
	
	[self updateHeaderHeightForOrientation:self.interfaceOrientation];
	[self updateConfirmationVisibility];
	
	self.navigationItem.title = self.interaction.title;
	
	self.inputAccessoryView.layer.borderColor = [[UIColor colorWithRed:215/255.0f green:219/255.0f blue:223/255.0f alpha:1.0f] CGColor];
	self.inputAccessoryView.layer.borderWidth = 0.5;
	
	self.messageView.text = self.draftMessage ?: @"";
	
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
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
	}];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	NSString *message = self.messageView.text;
	if (message && ![message isEqualToString:@""]) {
		[self.messageView becomeFirstResponder];
	}
	
//	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSString *message = self.messageView.text;
	if (message) {
		[[NSUserDefaults standardUserDefaults] setObject:message forKey:ATMessageCenterDraftMessageKey];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATMessageCenterDraftMessageKey];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataSource numberOfMessageGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfMessagesInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ATMessageCenterMessageType type = [self.dataSource cellTypeAtIndexPath:indexPath];
	
	if (type == ATMessageCenterMessageTypeMessage) {
		ATMessageCenterMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
	
		cell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		cell.dateLabel.text = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageAtIndexPath:indexPath]];
		
		return cell;
	} else {
		ATMessageCenterReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		cell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		cell.replyLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		
		NSString *dateString = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageAtIndexPath:indexPath]];
		NSString *userString = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		cell.dateLabel.text = [NSString stringWithFormat:ATLocalizedString(@"%@ - from %@", @"<date> - from <user>"), dateString, userString];
		
		return cell;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat marginsAndStuff = [self.dataSource cellTypeAtIndexPath:indexPath] == ATMessageCenterMessageTypeMessage ? 30.0 : 74.0;

	// Support iOS 6-style table views
	if (![self.tableView respondsToSelector:@selector(estimatedRowHeight)]) {
		marginsAndStuff += 18.0;
	}
	
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - marginsAndStuff;
	CGFloat dateLabelAndStuff = 37.0;
	
	CGSize labelSize = [labelText sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(effectiveLabelWidth, MAXFLOAT)];
	
	return labelSize.height + dateLabelAndStuff;
}

#pragma mark Fetch results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		[self.tableView endUpdates];
	} @catch (NSException *exception) {
		ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
	
	[self updateConfirmationVisibility];
	[self scrollToLastReply];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
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

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)updateConfirmationVisibility {
	self.confirmationView.confirmationHidden = self.dataSource.lastMessageIsReply;
}

- (void)scrollToLastReply {
	// TODO: implement me. 
}

@end
