//
//  ATSurveyViewController.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATDefaultTextView.h"
#import "ATInteraction.h"

@class ATCellTextView;
@class ATCellTextField;
@class ATSurvey;
@class ATSurveyQuestion;

@interface ATSurveyViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate> {
@private
	ATSurvey *survey;
	UITableView *tableView;
	UITableViewCell *activeTextEntryCell;
	ATCellTextView *activeTextView;
	ATCellTextField *activeTextField;
	
	NSString *errorText;
	
	NSMutableSet *sentNotificationsAboutQuestionIDs;
	
	NSDate *startedSurveyDate;
}
@property (nonatomic, copy) ATInteraction *interaction;
@property (nonatomic, copy) NSString *errorText;
- (id)initWithSurvey:(ATSurvey *)survey;
- (IBAction)sendSurvey;
@end

@protocol ATCellTextEntry <NSObject>
@property (nonatomic, retain) NSIndexPath *cellPath;
@property (nonatomic, retain) ATSurveyQuestion *question;
@property (nonatomic, copy) NSString *text;
- (CGRect)frame;
- (BOOL)becomeFirstResponder;
@end

@interface ATCellTextView : ATDefaultTextView <ATCellTextEntry> {
@private
	NSIndexPath *cellPath;
	ATSurveyQuestion *question;
}
@property (nonatomic, retain) NSIndexPath *cellPath;
@property (nonatomic, retain) ATSurveyQuestion *question;
@end

@interface ATCellTextField : UITextField <ATCellTextEntry> {
@private
	NSIndexPath *cellPath;
	ATSurveyQuestion *question;
}
@property (nonatomic, retain) NSIndexPath *cellPath;
@property (nonatomic, retain) ATSurveyQuestion *question;
@end
