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
#import "ATFeedback.h"
#import "ATFeedbackController.h"
#import "ATFeedbackMetrics.h"
#import "ATFeedbackTask.h"
#import "ATTask.h"
#import "ATTaskQueue.h"

enum {
	kSectionTasks,
	kSectionCount
};

@interface ATInfoViewController (Private)
- (void)setup;
- (void)teardown;
- (void)reload;
@end

@implementation ATInfoViewController
@synthesize tableView, headerView;

- (id)initWithFeedbackController:(ATFeedbackController *)aController {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		self = [super initWithNibName:@"ATInfoViewController" bundle:[ATConnect resourceBundle]];
	} else {
		self = [super initWithNibName:@"ATInfoViewController_iPad" bundle:[ATConnect resourceBundle]];
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	controller = [aController retain];
	return self;
}

- (void)dealloc {
	[controller release], controller = nil;
	[self teardown];
	[super dealloc];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidShowWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeInfo] forKey:ATFeedbackWindowTypeKey]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setup];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[headerView release], headerView = nil;
	self.tableView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	if (controller != nil) {
		[controller unhide:animated];
		[controller release], controller = nil;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}

- (IBAction)done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeInfo] forKey:ATFeedbackWindowTypeKey]];
}

- (IBAction)openApptentiveDotCom:(id)sender {
	[[UIApplication sharedApplication] openURL:[[ATBackend sharedBackend] apptentiveHomepageURL]];
}

- (IBAction)openPrivacyPolicy:(id)sender {
	[[UIApplication sharedApplication] openURL:[[ATBackend sharedBackend] apptentivePrivacyPolicyURL]];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		return [queue countOfTasksWithTaskNamesInSet:[NSSet setWithObject:@"feedback"]];
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *taskCellIdentifier = @"ATTaskProgressCellIdentifier";
	UITableViewCell *result = nil;
	if (indexPath.section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		ATTask *task = [queue taskAtIndex:indexPath.row withTaskNameInSet:[NSSet setWithObject:@"feedback"]];
		result = [aTableView dequeueReusableCellWithIdentifier:taskCellIdentifier];
		if (!result) {
			UINib *nib = [UINib nibWithNibName:@"ATTaskProgressCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			result = progressCell;
			[[result retain] autorelease];
			[progressCell release], progressCell = nil;
		}
		
		UILabel *label = (UILabel *)[result viewWithTag:1];
		UIProgressView *progressView = (UIProgressView *)[result viewWithTag:2];
		UILabel *detailLabel = (UILabel *)[result viewWithTag:4];
		
		if ([task isKindOfClass:[ATFeedbackTask class]]) {
			ATFeedbackTask *feedbackTask = (ATFeedbackTask *)task;
			label.text = feedbackTask.feedback.text;
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
	} else {
		NSAssert(NO, @"Unknown section.");
	}
	return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return kSectionCount;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	if (section == kSectionTasks) {
		result = NSLocalizedString(@"Running Tasks", @"Running tasks section header");
	}
	return result;
}

- (NSString *)tableView:(UITableView *)aTableView titleForFooterInSection:(NSInteger)section {
	NSString *result = nil;
	if (section == kSectionTasks) {
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		if ([queue count]) {
			result = NSLocalizedString(@"These are the pieces of feedback which are currently being submitted.", @"Section footer for feedback being uploaded.");
		} else {
			result = NSLocalizedString(@"No feedback waiting to upload.", @"Section footer for no feedback being updated.");
		}
	}
	return result;
}
@end


@implementation ATInfoViewController (Private)
- (void)setup {
	if (headerView) {
		[headerView release], headerView = nil;
	}
	UIImage *logoImage = [ATBackend imageNamed:@"at_logo_info"];
	UINib *nib = [UINib nibWithNibName:@"ATAboutApptentiveView" bundle:[ATConnect resourceBundle]];
	[nib instantiateWithOwner:self options:nil];
	UIImageView *logoView = (UIImageView *)[headerView viewWithTag:2];
	logoView.image = logoImage;
	CGRect f = logoView.frame;
	f.size = logoImage.size;
	logoView.frame = f;
	//tableView.delegate = self;
	tableView.dataSource = self;
	tableView.tableHeaderView = self.headerView;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ATAPIRequestStatusChanged object:nil];
}

- (void)teardown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[headerView release], headerView = nil;
	self.tableView = nil;
}

- (void)reload {
	[self.tableView reloadData];
}
@end
