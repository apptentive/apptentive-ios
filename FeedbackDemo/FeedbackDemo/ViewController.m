//
//  ViewController.m
//  FeedbackDemo
//
//  Created by Frank Schmitt on 4/30/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "ViewController.h"
#import "Apptentive.h"

// The "Apptentive_Private" header is used only for testing purposes in the demo app.
// Please do not use it in any live apps in the App Store.
#import "Apptentive+Debugging.h"

typedef NS_ENUM(NSInteger, TableViewSection) {
	kMessageCenterSection,
	kEventSection,
	kInteractionSection,
	kSectionCount
};


@interface ViewController ()

@property (strong, nonatomic) NSArray *events;
@property (strong, nonatomic) NSArray *interactions;

@end


@implementation ViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ApptentiveMessageCenterUnreadCountChangedNotification object:nil];

	self.interactions = [Apptentive sharedConnection].engagementInteractions;

#warning Add your own events below to trigger them from this app.
	self.events = @[@"event_1", @"event_2", @"event_3", @"event_4", @"event_5"];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)unreadMessageCountChanged:(NSNotification *)notification {
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kMessageCenterSection]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Actions

- (IBAction)refreshInteractions:(id)sender {
	self.interactions = [Apptentive sharedConnection].engagementInteractions;

	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kInteractionSection] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)buyStuff:(id)sender {
	[[[UIAlertView alloc] initWithTitle:@"Example Purchase" message:@"Tap “Purchase” to engage a commerce event." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Purchase", nil] show];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex) {
		// Example of how to attach sales data to an event.
		NSDictionary *commerceItem = [Apptentive extendedDataCommerceItemWithItemID:@"SKU_123" name:@"unlock_everything" category:@"in_app_purchase" price:@(4.99) quantity:@(1) currency:@"USD"];
		NSDictionary *commerce = [Apptentive extendedDataCommerceWithTransactionID:@"123" affiliation:@"app_store" revenue:@(4.99) shipping:@(0) tax:@(1) currency:@"USD" commerceItems:@[commerceItem]];
		NSArray *extendedData = @[[Apptentive extendedDataDate:[NSDate date]], [Apptentive extendedDataLocationForLatitude:14 longitude:10], commerce];
		[[Apptentive sharedConnection] engage:@"event_with_data" withCustomData:@{ @"customDataKey": @"customDataValue" } withExtendedData:extendedData fromViewController:self];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kMessageCenterSection:
			return 1;

		case kEventSection:
			return self.events.count;

		case kInteractionSection:
			return MAX(self.interactions.count, 1);

		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;

	switch (indexPath.section) {
		case kMessageCenterSection:
			cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCenter" forIndexPath:indexPath];
			cell.accessoryView = [[Apptentive sharedConnection] unreadMessageCountAccessoryView:YES];
			break;

		case kEventSection:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Event" forIndexPath:indexPath];

			cell.textLabel.text = [NSString stringWithFormat:@"Engage “%@” event", self.events[indexPath.row]];
			break;

		case kInteractionSection:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Interaction" forIndexPath:indexPath];

			if (self.interactions.count > 0) {
				cell.textLabel.text = [[Apptentive sharedConnection] engagementInteractionNameAtIndex:indexPath.row];
				cell.detailTextLabel.text = [[Apptentive sharedConnection] engagementInteractionTypeAtIndex:indexPath.row];
			} else {
				cell.textLabel.text = @"Refresh Interactions…";
				cell.detailTextLabel.text = nil;
			}

			break;
	}

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kMessageCenterSection:
			return @"Message Center";

		case kEventSection:
			return @"Events";

		case kInteractionSection:
			return @"Test Interactions";

		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == kSectionCount - 1) {
		return [NSString stringWithFormat:@"ApptentiveConnect v%@", kApptentiveVersionString];
	} else {
		return nil;
	}
}


#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case kMessageCenterSection:
			[[Apptentive sharedConnection] presentMessageCenterFromViewController:self];
			break;

		case kEventSection:
			[[Apptentive sharedConnection] engage:self.events[indexPath.row] fromViewController:self];
			break;

		case kInteractionSection:
			if (self.interactions.count > 0) {
				[[Apptentive sharedConnection] presentInteractionAtIndex:indexPath.row fromViewController:self];
			} else {
				[self refreshInteractions:tableView];
			}
			break;
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
