//
//  ATInfoViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/23/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATInfoViewController.h"
#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Debugging.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATFeedback.h"
#import "ATFeedbackMetrics.h"
#import "ATFeedbackTask.h"
#import "ATLogViewController.h"
#import "ATMessageTask.h"
#import "ATTask.h"
#import "ATTaskQueue.h"
#import "ATTextMessage.h"


enum {
	kSectionTasks,
	kSectionDebugLog,
	kSectionVersion,
};

@interface ATInfoViewController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UITextView *apptentiveDescriptionTextView;
@property (strong, nonatomic) IBOutlet UITextView *apptentivePrivacyTextView;
@property (strong, nonatomic) IBOutlet UIButton *findOutMoreButton;
@property (strong, nonatomic) IBOutlet UIButton *gotoPrivacyPolicyButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *progressCell;
@property (assign, nonatomic) BOOL showingDebugController;
@property (strong, nonatomic) NSMutableArray *logicalSections;

@end

@interface ATInfoViewController (Private)
- (void)setup;
- (void)reload;
@end

@implementation ATInfoViewController {
}

- (id)init {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		self = [super initWithNibName:@"ATInfoViewController" bundle:[ATConnect resourceBundle]];
	} else {
		self = [super initWithNibName:@"ATInfoViewController_iPad" bundle:[ATConnect resourceBundle]];
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.showingDebugController) {
		self.showingDebugController = NO;
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidShowWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeInfo] forKey:ATFeedbackWindowTypeKey]];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setup];
}

- (void)viewDidUnload {
	[self setApptentiveDescriptionTextView:nil];
	[self setApptentivePrivacyTextView:nil];
	[self setFindOutMoreButton:nil];
	[self setGotoPrivacyPolicyButton:nil];
	[super viewDidUnload];
	self.headerView = nil;
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	self.tableView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeInfo] forKey:ATFeedbackWindowTypeKey]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}

- (IBAction)openApptentiveDotCom:(id)sender {
	[[UIApplication sharedApplication] openURL:[[ATBackend sharedBackend] apptentiveHomepageURL]];
}

- (IBAction)openPrivacyPolicy:(id)sender {
	[[UIApplication sharedApplication] openURL:[[ATBackend sharedBackend] apptentivePrivacyPolicyURL]];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger physicalSection = indexPath.section;
	NSUInteger section = [[self.logicalSections objectAtIndex:physicalSection] integerValue];
	if (section == kSectionDebugLog) {
		self.showingDebugController = YES;
		ATLogViewController *vc = [[ATLogViewController alloc] init];
		[self.navigationController pushViewController:vc animated:YES];
		vc = nil;
	}
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)physicalSection {
	NSUInteger section = [[self.logicalSections objectAtIndex:physicalSection] integerValue];
	
	if (section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		return [queue countOfTasksWithTaskNamesInSet:[NSSet setWithObjects:@"feedback", @"message", @"survey response", nil]];
	} else if (section == kSectionDebugLog) {
		return 1;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *taskCellIdentifier = @"ATTaskProgressCellIdentifier";
	static NSString *logCellIdentifier = @"ATLogViewCellIdentifier";
	UITableViewCell *result = nil;
	
	NSUInteger physicalSection = indexPath.section;
	NSUInteger section = [[self.logicalSections objectAtIndex:physicalSection] integerValue];
	
	if (section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		ATTask *task = [queue taskAtIndex:indexPath.row withTaskNameInSet:[NSSet setWithObjects:@"feedback", @"message", @"survey response", nil]];
		result = [aTableView dequeueReusableCellWithIdentifier:taskCellIdentifier];
		if (!result) {
			UINib *nib = [UINib nibWithNibName:@"ATTaskProgressCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			result = self.progressCell;
			self.progressCell = nil;
		}
		
		UILabel *label = (UILabel *)[result viewWithTag:1];
		UIProgressView *progressView = (UIProgressView *)[result viewWithTag:2];
		UILabel *detailLabel = (UILabel *)[result viewWithTag:4];
		
		if ([task isKindOfClass:[ATFeedbackTask class]]) {
			ATFeedbackTask *feedbackTask = (ATFeedbackTask *)task;
			label.text = feedbackTask.feedback.text;
		} else if ([task isKindOfClass:[ATMessageTask class]]) {
			ATMessageTask *messageTask = (ATMessageTask *)task;
			NSString *messageID = [messageTask pendingMessageID];
			ATAbstractMessage *message = [ATAbstractMessage findMessageWithPendingID:messageID];
			if ([message isKindOfClass:[ATTextMessage class]]) {
				ATTextMessage *textMessage = (ATTextMessage *)message;
				label.text = textMessage.body;
			} else {
				label.text = [message description];
			}
		} else {
			label.text = [task description];
		}
		
		if (task.failed) {
			detailLabel.hidden = NO;
			if (task.lastErrorTitle) {
				detailLabel.text = [NSString stringWithFormat:@"Failed: %@", task.lastErrorTitle];
			}
			progressView.hidden = YES;
		} else if (task.inProgress) {
			detailLabel.hidden = YES;
			progressView.hidden = NO;
			progressView.progress = [task percentComplete];
		} else {
			detailLabel.hidden = NO;
			detailLabel.text = @"Waiting…";
			progressView.hidden = YES;
		}
	} else if (section == kSectionDebugLog) {
		result = [aTableView dequeueReusableCellWithIdentifier:logCellIdentifier];
		if (!result) {
			result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:logCellIdentifier];
		}
		result.textLabel.text = @"View Debug Logs";
	} else {
		NSAssert(NO, @"Unknown section.");
	}
	return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return [self.logicalSections count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)physicalSection {
	NSString *result = nil;
	
	NSUInteger section = [[self.logicalSections objectAtIndex:physicalSection] integerValue];
	if (section == kSectionTasks) {
		result = ATLocalizedString(@"Running Tasks", @"Running tasks section header");
	}
	return result;
}

- (NSString *)tableView:(UITableView *)aTableView titleForFooterInSection:(NSInteger)physicalSection {
	NSString *result = nil;
	NSUInteger section = [[self.logicalSections objectAtIndex:physicalSection] integerValue];
	if (section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		if ([queue count]) {
			result = ATLocalizedString(@"These are the pieces of feedback which are currently being submitted.", @"Section footer for feedback being uploaded.");
		} else {
			result = ATLocalizedString(@"No feedback waiting to upload.", @"Section footer for no feedback being updated.");
		}
	} else if (section == kSectionVersion) {
		result = [NSString stringWithFormat:@"ApptentiveConnect v%@", kATConnectVersionString];
	}
	return result;
}
@end


@implementation ATInfoViewController (Private)

- (void)setup {
	if (self.headerView) {
		self.headerView = nil;
	}
	self.logicalSections = [[NSMutableArray alloc] init];
	[self.logicalSections addObject:@(kSectionTasks)];
	if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsShowDebugPanel) {
		[self.logicalSections addObject:@(kSectionDebugLog)];
	}
	[self.logicalSections addObject:@(kSectionVersion)];
	
	UIImage *logoImage = [ATBackend imageNamed:@"at_logo_info"];
	UINib *nib = [UINib nibWithNibName:@"ATAboutApptentiveView" bundle:[ATConnect resourceBundle]];
	[nib instantiateWithOwner:self options:nil];
	UIImageView *logoView = (UIImageView *)[self.headerView viewWithTag:2];
	logoView.image = logoImage;
	CGRect f = logoView.frame;
	f.size = logoImage.size;
	logoView.frame = f;
	
	
	self.navigationItem.title = ATLocalizedString(@"About Apptentive", @"About Apptentive");
	self.apptentiveDescriptionTextView.text = ATLocalizedString(@"Apptentive is a feedback and communication service which allows the people who make this app to quickly get your feedback and better listen to you.", @"Description of Apptentive service in information screen.");
	[self.findOutMoreButton setTitle:ATLocalizedString(@"Find out more at apptentive.com", @"Title of button to open Apptentive.com") forState:UIControlStateNormal];
	self.apptentivePrivacyTextView.text = ATLocalizedString(@"Your feedback is hosted by Apptentive and is subject to Apptentive's privacy policy and the privacy policy of the developer of this app.", @"Description of Apptentive privacy policy.");
	[self.gotoPrivacyPolicyButton setTitle:ATLocalizedString(@"Go to Apptentive's Privacy Policy", @"Title for button to open Apptentive's privacy policy") forState:UIControlStateNormal];
	
	[self.tableView setAccessibilityIdentifier:@"ATInfoViewTable"];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.tableHeaderView = self.headerView;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ATAPIRequestStatusChanged object:nil];
}

- (void)reload {
	[self.tableView reloadData];
}
@end
