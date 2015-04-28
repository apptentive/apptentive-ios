//
//  ATInfoViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/23/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*! View controller for showing information about Apptentive, as well as the
 tasks which are currently in progress. */
@interface ATInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	IBOutlet UIView *headerView;
	IBOutlet UITableViewCell *progressCell;
@private
    NSMutableArray *logicalSections;
}
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UITextView *apptentiveDescriptionTextView;
@property (strong, nonatomic) IBOutlet UITextView *apptentivePrivacyTextView;
@property (strong, nonatomic) IBOutlet UIButton *findOutMoreButton;
@property (strong, nonatomic) IBOutlet UIButton *gotoPrivacyPolicyButton;

- (id)init;
- (IBAction)openApptentiveDotCom:(id)sender;
- (IBAction)openPrivacyPolicy:(id)sender;
@end
