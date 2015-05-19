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
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIView *headerView;
@property (retain, nonatomic) IBOutlet UILabel *apptentiveDescriptionTextView;
@property (retain, nonatomic) IBOutlet UILabel *apptentivePrivacyTextView;
@property (retain, nonatomic) IBOutlet UIButton *findOutMoreButton;
@property (retain, nonatomic) IBOutlet UIButton *gotoPrivacyPolicyButton;

- (id)init;
- (IBAction)openApptentiveDotCom:(id)sender;
- (IBAction)openPrivacyPolicy:(id)sender;
@end
