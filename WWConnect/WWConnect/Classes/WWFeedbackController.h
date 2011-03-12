//
//  WWFeedbackController.h
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WWFeedbackController : UIViewController {
    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *feedbackCell;
    IBOutlet UITableViewCell *nameCell;
}

@end
