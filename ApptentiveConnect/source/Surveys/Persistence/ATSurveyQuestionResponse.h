//
//  ATSurveyQuestionResponse.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/22/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATSurveyQuestionResponse : NSObject <NSCoding> {
@private
}
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, retain) NSObject<NSCoding> *response;

@end
