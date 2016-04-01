//
//  ATSurveyResponseTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveSurveyResponse.h"


@interface ApptentiveSurveyResponseTask : ATTask <ApptentiveAPIRequestDelegate>
@property (strong, nonatomic) NSString *pendingSurveyResponseID;
@end
