//
//  ATSurvey.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATSurveyQuestion.h"

@interface ATSurvey : NSObject {
@private
	NSMutableArray *questions;
}
@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *surveyDescription;
@property (nonatomic, readonly) NSArray *questions;

- (void)addQuestion:(ATSurveyQuestion *)question;
@end
