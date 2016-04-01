//
//  ATSurveyAnswer.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApptentiveSurveyAnswer : NSObject

- (instancetype)initWithJSON:(NSDictionary *)JSON;

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *value;

@end
