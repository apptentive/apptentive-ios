//
//  RootViewController.m
//  FeedbackDemo
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "RootViewController.h"
#import "ATConnect.h"
#import "ATAppRatingFlow.h"
#import "ATSurveys.h"
#import "defines.h"

enum kRootTableSections {
	kFeedbackSection,
	kRatingSection,
	kSurveySection,
	kSectionCount
};

@interface RootViewController ()
- (void)surveyBecameAvailable:(NSNotification *)notification;
@end

@implementation RootViewController

- (IBAction)showFeedback:(id)sender {
	ATConnect *connection = [ATConnect sharedConnection];
	connection.apiKey = kApptentiveAPIKey;
	
	[connection presentFeedbackControllerFromViewController:self];
}

- (IBAction)showRating:(id)sender {
	ATAppRatingFlow *flow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
	[flow showEnjoymentDialog:self];
}

- (void)viewDidLoad {
	ATConnect *connection = [ATConnect sharedConnection];
	connection.apiKey = kApptentiveAPIKey;
	self.navigationItem.title = @"Apptentive Demo";
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"at_logo_info"]];
	imageView.contentMode = UIViewContentModeCenter;
	self.tableView.tableHeaderView = imageView;
	[imageView release], imageView = nil;
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
	[ATSurveys checkForAvailableSurveys];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
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
	if (section == kFeedbackSection) {
		return 2;
	}
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	if (indexPath.section == kFeedbackSection) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Send Feedback";
		} else {
			cell.textLabel.text = @"Send Feedback with Screenshot";
		}
	} else if (indexPath.section == kRatingSection) {
		cell.textLabel.text = @"Start Rating Flow";
	} else if (indexPath.section == kSurveySection) {
		if ([ATSurveys hasSurveyAvailable]) {
			cell.textLabel.text = @"Show Survey";
			cell.textLabel.textColor = [UIColor blackColor];
		} else {
			cell.textLabel.text = @"No Survey Available";
			cell.textLabel.textColor = [UIColor grayColor];
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kFeedbackSection) {
		ATConnect *connection = [ATConnect sharedConnection];
		if (indexPath.row == 0) {
			connection.shouldTakeScreenshot = NO;
		} else if (indexPath.row == 1) {
			connection.shouldTakeScreenshot = YES;
		}
		[self showFeedback:nil];
	} else if (indexPath.section == kRatingSection) {
		[self showRating:nil];
	} else if (indexPath.section == kSurveySection) {
		if ([ATSurveys hasSurveyAvailable]) {
			[ATSurveys presentSurveyControllerFromViewController:self];
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	if (section == kFeedbackSection) {
		title = @"Feedback";
	} else if (section == kRatingSection) {
		title = @"Ratings";
	} else if (section == kSurveySection) {
		title = @"Surveys";
	}
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *title = nil;
	if (section == kFeedbackSection) {
		title = @"Opens feedback screen.";
	} else if (section == kRatingSection) {
		title = nil;
	} else if (section == kSurveySection) {
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
	[super dealloc];
}
@end
