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
@interface ATInfoViewController : UIViewController {
    IBOutlet UIView *headerView;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (IBAction)done:(id)sender;
@end
