//
//  ATSurvey.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATSurveyQuestion.h"

@interface ATSurvey : NSObject <NSCoding> {
@private
	NSMutableArray *questions;
}

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *surveyDescription;
@property (nonatomic, readonly) NSArray *questions;
@property (nonatomic, getter=responseIsRequired) BOOL responseRequired;
@property (nonatomic, assign) BOOL showSuccessMessage;
@property (nonatomic, copy) NSString *successMessage;

- (void)addQuestion:(ATSurveyQuestion *)question;

- (void)reset;

@end
