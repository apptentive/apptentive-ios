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

@interface ATCellTextView : ATDefaultTextView <ATCellTextEntry>
@property (nonatomic, strong) NSIndexPath *cellPath;
@property (nonatomic, strong) ATSurveyQuestion *question;
@end

@interface ATCellTextField : UITextField <ATCellTextEntry>
@property (nonatomic, strong) NSIndexPath *cellPath;
@property (nonatomic, strong) ATSurveyQuestion *question;
@end
