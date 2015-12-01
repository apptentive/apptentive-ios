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


@interface ATSurveyViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate>
@property (copy, nonatomic) ATInteraction *interaction;
@property (copy, nonatomic) NSString *errorText;
- (id)initWithSurvey:(ATSurvey *)survey;
- (IBAction)sendSurvey;
@end

@protocol ATCellTextEntry <NSObject>
@property (strong, nonatomic) NSIndexPath *cellPath;
@property (strong, nonatomic) ATSurveyQuestion *question;
@property (copy, nonatomic) NSString *text;
- (CGRect)frame;
- (BOOL)becomeFirstResponder;
@end


@interface ATCellTextView : ATDefaultTextView <ATCellTextEntry>
@property (strong, nonatomic) NSIndexPath *cellPath;
@property (strong, nonatomic) ATSurveyQuestion *question;
@end


@interface ATCellTextField : UITextField <ATCellTextEntry>
@property (strong, nonatomic) NSIndexPath *cellPath;
@property (strong, nonatomic) ATSurveyQuestion *question;
@end
