//
//  ATSurveyParser.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATSurvey.h"
#import "ATInteraction.h"

@interface ATSurveyParser : NSObject {
@private
	NSError *parserError;
}
- (NSError *)parserError;

- (ATSurvey *)surveyWithInteraction:(ATInteraction *)interaction;

@end
