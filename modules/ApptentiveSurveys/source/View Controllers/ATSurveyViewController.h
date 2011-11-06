//
//  ATSurveyViewController.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSurvey;

@interface ATSurveyViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
@private
	ATSurvey *survey;
	UITableView *tableView;
	UITextField *activeTextField;
}
- (id)initWithSurvey:(ATSurvey *)survey;
@end
