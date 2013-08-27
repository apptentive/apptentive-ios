//
//  ATSurveyGetSurveyTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyGetSurveyTask.h"
#import "ATBackend.h"
#import "ATSurveyParser.h"
#import "ATSurveysBackend.h"
#import "ATWebClient.h"
#import "ATWebClient+SurveyAdditions.h"
#import "PJSONKit.h"

@interface ATSurveyGetSurveyTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATSurveyGetSurveyTask
- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

- (void)dealloc {
	[self teardown];
	[super dealloc];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	self.failureOkay = YES;
	if (checkSurveyRequest == nil) {
		ATWebClient *client = [ATWebClient sharedClient];
		checkSurveyRequest = [[client requestForGettingSurvey] retain];
		checkSurveyRequest.delegate = self;
		self.inProgress = YES;
		[checkSurveyRequest start];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (checkSurveyRequest) {
		checkSurveyRequest.delegate = nil;
		[checkSurveyRequest cancel];
		[checkSurveyRequest release], checkSurveyRequest = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (checkSurveyRequest) {
		return [checkSurveyRequest percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"survey check";
}


#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		if (request == checkSurveyRequest) {
			ATSurveyParser *parser = [[ATSurveyParser alloc] init];
			ATSurvey *survey = [parser parseSurvey:(NSData *)result];
			if (survey == nil) {
				NSLog(@"An error occurred parsing survey: %@", [parser parserError]);
			} else {
				[[ATSurveysBackend sharedBackend] didReceiveNewSurvey:survey];
			}
			checkSurveyRequest.delegate = nil;
			[checkSurveyRequest release], checkSurveyRequest = nil;
			[parser release], parser = nil;
			self.finished = YES;
		}
		[self release];
	}
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)request {
	@synchronized(self) {
		[self retain];
		if (request == checkSurveyRequest) {
			NSLog(@"Survey request failed: %@: %@", request.errorTitle, request.errorMessage);
			self.failed = YES;
			[self stop];
		}
		[self release];
	}
}
@end

@implementation ATSurveyGetSurveyTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end
