//
//  ATMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATResizingTextView.h"

@interface ATMessageCenterViewController : UIViewController <ATResizingTextViewDelegate, NSFetchedResultsControllerDelegate, UIScrollViewDelegate, UITableViewDataSource,  UITableViewDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIView *composerView;
@property (retain, nonatomic) IBOutlet UIImageView *composerBackgroundView;
@property (retain, nonatomic) IBOutlet UIButton *attachmentButton;
@property (retain, nonatomic) IBOutlet ATResizingTextView *textView;
@property (retain, nonatomic) IBOutlet UIButton *sendButton;
@property (retain, nonatomic) IBOutlet UIView *attachmentView;

- (IBAction)donePressed:(id)sender;
- (IBAction)sendPressed:(id)sender;
- (IBAction)paperclipPressed:(id)sender;
@end
