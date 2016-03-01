//
//  ATSurveyLayoutAttributes.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyLayoutAttributes.h"

@implementation ATSurveyLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
	ATSurveyLayoutAttributes *result = [super copyWithZone:zone];

	result.valid = self.valid;

	return result;
}

- (BOOL)isEqual:(id)object {
	return [super isEqual:object] && self.valid == ((ATSurveyLayoutAttributes *)object).valid;
}

@end
