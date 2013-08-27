//
//  ATWebClient+SurveyAdditions.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATWebClient+SurveyAdditions.h"
#import "ATWebClient_Private.h"
#import "ATAPIRequest.h"
#import "ATSurveyResponse.h"
#import "ATURLConnection.h"
#import "PJSONKit.h"

#define kSurveysChannelName @"Apptentive-Surveys"

@implementation ATWebClient (SurveyAdditions)
- (ATAPIRequest *)requestForGettingSurvey {
	NSString *urlString = [NSString stringWithFormat:@"%@/surveys/active", [self baseURLString]];
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:urlString]];
	conn.timeoutInterval = 20.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeData;
	return [request autorelease];
}


- (ATAPIRequest *)requestForPostingSurveyResponse:(ATSurveyResponse *)surveyResponse {
	NSError *error = nil;
	NSString *postString = [[surveyResponse apiJSON] ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		NSLog(@"ATWebClient+SurveyAdditions: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"records"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	
	conn.timeoutInterval = 240.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kSurveysChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}
@end
