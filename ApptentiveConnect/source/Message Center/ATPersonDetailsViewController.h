//
//  ATPersonDetailsViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATPersonDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
	@private
	UIAlertView *emailRequiredAlert;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *logoButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UILabel *poweredByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *logoImage;

- (IBAction)donePressed:(id)sender;
- (IBAction)logoPressed:(id)sender;
@end
