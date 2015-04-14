//
//  RootViewController.m
//  FeedbackDemo
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "RootViewController.h"
#import "ATConnect.h"
#import "defines.h"

// The "ATConnect_Private" header is used only for testing purposes in the demo app.
// Please do not use it in any live apps in the App Store.
#import "ATConnect_Private.h"

enum kRootTableSections {
	kMessageCenterSection,
	kEventSection,
	kInteractionSection,
	kSectionCount
};

enum kMessageCenterRows {
	kMessageCenterRowShowMessageCenter,
	kMessageCenterRowCount
};

enum kEventRows {
	kEventRowEvent1,
	kEventRowEvent2,
	kEventRowEvent3,
	kEventRowEvent4,
	kEventRowEvent5,
	kEventRowCount
};

NSInteger const refreshInteractionsCellTag = 555;

@interface RootViewController ()
- (void)surveyBecameAvailable:(NSNotification *)notification;
- (void)unreadMessageCountChanged:(NSNotification *)notification;
- (void)checkForProperConfiguration;
@end

@implementation RootViewController

- (void)viewDidLoad {
	self.navigationItem.title = @"Apptentive Demo";
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"at_logo_info"]];
	imageView.contentMode = UIViewContentModeCenter;
	self.tableView.tableHeaderView = imageView;
	[imageView release], imageView = nil;
	[super viewDidLoad];
	
	tags = [[NSSet alloc] initWithObjects:@"demoTag", nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ATMessageCenterUnreadCountChangedNotification object:nil];
	
	// Engage an event with customData and extendedData
	NSDictionary *commerceItem = [ATConnect extendedDataCommerceItemWithItemID:@"SKU_123" name:@"unlock_everything" category:@"in_app_purchase" price:@(4.99) quantity:@(1) currency:@"USD"];
	NSDictionary *commerce = [ATConnect extendedDataCommerceWithTransactionID:@"123" affiliation:@"app_store" revenue:@(4.99) shipping:@(0) tax:@(1) currency:@"USD" commerceItems:@[commerceItem]];
	NSArray *extendedData = @[[ATConnect extendedDataDate:[NSDate date]], [ATConnect extendedDataLocationForLatitude:14 longitude:10], commerce];
	[[ATConnect sharedConnection] engage:@"event_with_data" withCustomData:@{@"customDataKey":@"customDataValue"} withExtendedData:extendedData fromViewController:self];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
	NSLog(@"Apptentive Notification: survey became available");
	[self.tableView reloadData];
}

- (void)unreadMessageCountChanged:(NSNotification *)notification {
	NSLog(@"Apptentive Notification: unread message count changed");
	[self.tableView reloadData];
}

- (void)checkForProperConfiguration {
	static BOOL checkedAlready = NO;
	if (checkedAlready) {
		// Don't display more than once.
		return;
	}
	checkedAlready = YES;
	
	NSString *apiKey = [ATConnect sharedConnection].apiKey ?: kApptentiveAPIKey;
	NSString *appID = [ATConnect sharedConnection].appID ?: kApptentiveAppID;
	if ([apiKey isEqualToString:@"ApptentiveApiKey"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Set API Key" message:@"This demo app will not work properly until you set your API key in defines.h" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert autorelease];
	} else if ([appID isEqualToString:@"ExampleAppID"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Set App ID" message:@"This demo app won't be able to show your app in the app store until you set your App ID in defines.h" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert autorelease];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self checkForProperConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kEventSection) {
		return kEventRowCount;
	} else if (section == kMessageCenterSection) {
		return kMessageCenterRowCount;
	} else if (section == kInteractionSection) {
		NSInteger interactionsCount = [[ATConnect sharedConnection] engagementInteractions].count;

		return interactionsCount ?: 1;
	}
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryView = nil;
	}
	
	cell.textLabel.textColor = [UIColor blackColor];
	
	if (indexPath.section == kEventSection) {
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;

		if (indexPath.row == kEventRowEvent1) {
			cell.textLabel.text = [NSString stringWithFormat:@"Engage `%@` event", kApptentiveEvent1];
		} else if (indexPath.row == kEventRowEvent2) {
			cell.textLabel.text = [NSString stringWithFormat:@"Engage `%@` event", kApptentiveEvent2];
		} else if (indexPath.row == kEventRowEvent3) {
			cell.textLabel.text = [NSString stringWithFormat:@"Engage `%@` event", kApptentiveEvent3];
		} else if (indexPath.row == kEventRowEvent4) {
			cell.textLabel.text = [NSString stringWithFormat:@"Engage `%@` event", kApptentiveEvent4];
		} else if (indexPath.row == kEventRowEvent5) {
			cell.textLabel.text = [NSString stringWithFormat:@"Engage `%@` event", kApptentiveEvent5];
		}
	} else if (indexPath.section == kMessageCenterSection) {
		cell.detailTextLabel.text = nil;

		if (indexPath.row == kMessageCenterRowShowMessageCenter) {
			cell.textLabel.text = @"Message Center";
			UILabel *unreadLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			unreadLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[ATConnect sharedConnection] unreadMessageCount]];
			unreadLabel.backgroundColor = [UIColor grayColor];
			unreadLabel.textColor = [UIColor whiteColor];
			unreadLabel.textAlignment = NSTextAlignmentCenter;
			unreadLabel.font = [UIFont boldSystemFontOfSize:17];
			[unreadLabel sizeToFit];
			
			CGRect paddedFrame = unreadLabel.frame;
			paddedFrame.size.width += 10;
			if (paddedFrame.size.width < paddedFrame.size.height) {
				paddedFrame.size.width = paddedFrame.size.height;
			}
			unreadLabel.frame = paddedFrame;
			unreadLabel.layer.cornerRadius = unreadLabel.frame.size.height / 2;
			unreadLabel.layer.masksToBounds = YES;
			
			cell.accessoryView = [unreadLabel autorelease];
		}
	} else if (indexPath.section == kInteractionSection) {
		NSInteger interactionsCount = [[ATConnect sharedConnection] engagementInteractions].count;
		
		if (interactionsCount == 0) {
			cell.textLabel.text = @"Refresh Interactions...";
			cell.detailTextLabel.text = nil;
			cell.accessoryView = nil;
			cell.tag = refreshInteractionsCellTag;
		}
		else {
			cell.textLabel.text = [[ATConnect sharedConnection] engagementInteractionNameAtIndex:indexPath.row];
			cell.detailTextLabel.text = [[ATConnect sharedConnection] engagementInteractionTypeAtIndex:indexPath.row];
			cell.accessoryView = nil;
			cell.tag = 0;
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kEventSection) {
		if (indexPath.row == kEventRowEvent1) {
			[[ATConnect sharedConnection] engage:kApptentiveEvent1 fromViewController:self];
		} else if (indexPath.row == kEventRowEvent2) {
			[[ATConnect sharedConnection] engage:kApptentiveEvent2 fromViewController:self];
		} else if (indexPath.row == kEventRowEvent3) {
			[[ATConnect sharedConnection] engage:kApptentiveEvent3 fromViewController:self];
		} else if (indexPath.row == kEventRowEvent4) {
			[[ATConnect sharedConnection] engage:kApptentiveEvent4 fromViewController:self];
		} else if (indexPath.row == kEventRowEvent5) {
			 [[ATConnect sharedConnection] engage:kApptentiveEvent5 fromViewController:self];
		}
	} else if (indexPath.section == kMessageCenterSection) {
		if (indexPath.row == kMessageCenterRowShowMessageCenter) {
			BOOL sendWithCustomData = arc4random_uniform(2);
			if (sendWithCustomData) {
				[[ATConnect sharedConnection] presentMessageCenterFromViewController:self withCustomData:@{@"sentViaFeedbackDemo": @YES, @"randomlyChosenToHaveCustomData": @YES}];
			} else {
				[[ATConnect sharedConnection] presentMessageCenterFromViewController:self];
			}
		}
	} else if (indexPath.section == kInteractionSection) {
		if (indexPath.row == 0 && [tableView cellForRowAtIndexPath:indexPath].tag == refreshInteractionsCellTag) {
			[self.tableView reloadData];
		}
		else if (indexPath.row < [[ATConnect sharedConnection] engagementInteractions].count) {
			[[ATConnect sharedConnection] presentInteractionAtIndex:indexPath.row fromViewController:self];
		} else {
			[self.tableView reloadData];
		}
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	if (section == kMessageCenterSection) {
		title = @"Message Center";
	} else if (section == kEventSection) {
		title = @"Events";
	} else if (section == kInteractionSection) {
		title = @"Interactions";
	}
	
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *title = nil;
	if (section == kSectionCount - 1) {
		title = [NSString stringWithFormat:@"ApptentiveConnect v%@", kATConnectVersionString];
	}
	return title;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[tags release], tags = nil;
	[super dealloc];
}
@end
