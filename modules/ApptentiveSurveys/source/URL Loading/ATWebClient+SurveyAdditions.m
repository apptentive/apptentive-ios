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

@implementation ATWebClient (SurveyAdditions)
- (ATAPIRequest *)requestForGettingSurvey {
    NSString *urlString = [NSString stringWithFormat:@"%@/surveys", [self baseURLString]];
    ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:urlString]];
    conn.timeoutInterval = 20.0;
    ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
    request.returnType = ATAPIRequestReturnTypeData;
    return [request autorelease];
}


- (ATAPIRequest *)requestForPostingSurveyResponse:(ATSurveyResponse *)surveyResponse {
	NSDictionary *postData = [surveyResponse apiDictionary];
    NSString *url = [NSString stringWithFormat:@"%@/surveys", [self baseURLString]];
    ATURLConnection *conn = nil;
    
	conn = [self connectionToPost:[NSURL URLWithString:url] parameters:postData];
	
    conn.timeoutInterval = 240.0;
    ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
    request.returnType = ATAPIRequestReturnTypeData;
    return [request autorelease];
}
@end
