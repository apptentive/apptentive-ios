//
//  ATSurveyResponseTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyResponseTask.h"
#import "ATBackend.h"
#import "ATJSONSerialization.h"
#import "ATWebClient+SurveyAdditions.h"

#define kATPendingMessageTaskCodingVersion 1

@interface ATSurveyResponseTask (Private)
- (void)setup;
- (void)teardown;
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end

@implementation ATSurveyResponseTask
@synthesize pendingSurveyResponseID;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATPendingMessageTaskCodingVersion) {
			self.pendingSurveyResponseID = [coder decodeObjectForKey:@"pendingSurveyResponseID"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPendingMessageTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.pendingSurveyResponseID forKey:@"pendingSurveyResponseID"];
}

- (void)dealloc {
	[self teardown];
	[pendingSurveyResponseID release], pendingSurveyResponseID = nil;
	[super dealloc];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		ATSurveyResponse *response = [[ATSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID] retain];
		if (response == nil) {
			ATLogError(@"Warning: Response was nil in survey response task.");
			self.finished = YES;
			return;
		}
		request = [[[ATWebClient sharedClient] requestForPostingSurveyResponse:response] retain];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
		[response release], response = nil;
	}
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"survey response";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		
		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			ATLogError(@"Survey response result is not NSDictionary!");
			self.failed = YES;
		}
		[self stop];
		[self release];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		[self retain];
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		
		ATSurveyResponse *response = [[ATSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID] retain];
		if (response == nil) {
			ATLogError(@"Warning: Survey response went away during task.");
			self.finished = YES;
			return;
		}
		
		if (sender.errorResponse != nil) {
			NSError *parseError = nil;
			NSObject *errorObject = [ATJSONSerialization JSONObjectWithString:sender.errorResponse error:&parseError];
			if (errorObject != nil && [errorObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *errorDictionary = (NSDictionary *)errorObject;
				if ([errorDictionary objectForKey:@"errors"]) {
					ATLogInfo(@"ATAPIRequest server error: %@", [errorDictionary objectForKey:@"errors"]);
				}
			} else if (errorObject == nil) {
				ATLogError(@"Error decoding error response: %@", parseError);
			}
			[response setPendingState:@(ATPendingSurveyResponseError)];
		}
		NSError *error = nil;
		NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
		if (![context save:&error]) {
			ATLogError(@"Failed to save survey response after API failure: %@", error);
		}
		ATLogInfo(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		if (self.failureCount > 2) {
			self.finished = YES;
		} else {
			self.failed = YES;
		}
		[self stop];
		[response release], response = nil;
		[self release];
	}
}
@end

@implementation ATSurveyResponseTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}

- (BOOL)processResult:(NSDictionary *)jsonResponse {
	ATLogDebug(@"Getting json result: %@", jsonResponse);
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	ATSurveyResponse *response = [[ATSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID] retain];
	if (response == nil) {
		ATLogError(@"Warning: Response went away during task.");
		return YES;
	}
	[response updateWithJSON:jsonResponse];
	response.pendingState = [NSNumber numberWithInt:ATPendingSurveyResponseConfirmed];
	
	NSError *error = nil;
	if (![context save:&error]) {
		ATLogError(@"Failed to save new response: %@", error);
		[response release], response = nil;
		return NO;
	}
	[response release], response = nil;
	return YES;
}
@end
