//
//  ATWebClient+SurveyAdditions.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATWebClient+SurveyAdditions.h"
#import "ATWebClient_Private.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"
#import "ATAPIRequest.h"
#import "ATConversationUpdater.h"
#import "ATJSONSerialization.h"
#import "ATSurveyResponse.h"
#import "ATURLConnection.h"
#import "ATConversation.h"


@implementation ATWebClient (SurveyAdditions)

- (ATAPIRequest *)requestForPostingSurveyResponse:(ATSurveyResponse *)surveyResponse {
	ATConversation *conversation = [ATConnect sharedConnection].backend.currentConversation;
	if (!conversation.token) {
		ATLogError(@"No current conversation.");
		return nil;
	}

	NSError *error = nil;
	NSString *postString = [ATJSONSerialization stringWithJSONObject:[surveyResponse apiJSON] options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"ATWebClient+SurveyAdditions: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *path = [NSString stringWithFormat:@"/surveys/%@/respond", surveyResponse.surveyID];

	ATURLConnection *conn = [self connectionToPost:path JSON:postString];
	conn.timeoutInterval = 240.0;
	[self updateConnection:conn withOAuthToken:conversation.token];

	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}
@end
