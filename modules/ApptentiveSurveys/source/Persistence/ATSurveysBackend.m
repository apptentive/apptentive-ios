//
//  ATSurveysBackend.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveysBackend.h"
#import "ATSurvey.h"
#import "ATSurveys.h"
#import "ATSurveyParser.h"
#import "ATSurveyViewController.h"
#import "JSONKit.h"

@implementation ATSurveysBackend

+ (ATSurveysBackend *)sharedBackend {
	static ATSurveysBackend *sharedBackend = nil;
	@synchronized(self) {
		if (sharedBackend == nil) {
			sharedBackend = [[ATSurveysBackend alloc] init];
		}
	}
	return sharedBackend;
}

- (void)dealloc {
	checkSurveyRequest.delegate = nil;
	[checkSurveyRequest release], checkSurveyRequest = nil;
	[super dealloc];
}

- (void)checkForAvailableSurveys {
	if (checkSurveyRequest == nil) {
		NSLog(@"checking for surveys");
		ATWebClient *client = [ATWebClient sharedClient];
		checkSurveyRequest = [[client requestForGettingSurvey] retain];
		checkSurveyRequest.delegate = self;
		[checkSurveyRequest start];
	}
}

- (ATSurvey *)currentSurvey {
	return currentSurvey;
}


- (void)presentSurveyControllerFromViewController:(UIViewController *)viewController {
	if (currentSurvey == nil) {
		return;
	}
	ATSurveyViewController *vc = [[ATSurveyViewController alloc] initWithSurvey:currentSurvey];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [viewController presentModalViewController:nc animated:YES];
    } else {
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [viewController presentModalViewController:nc animated:YES];
    }
    [nc release];
	[vc release];
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result {
	if (request == checkSurveyRequest) {
		ATSurveyParser *parser = [[ATSurveyParser alloc] init];
		ATSurvey *survey = [parser parseSurvey:(NSData *)result];
		if (survey == nil) {
			NSLog(@"An error occurred parsing survey: %@", [parser parserError]);
		} else {
			[currentSurvey release], currentSurvey = nil;
			currentSurvey = [survey retain];
			[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyNewSurveyAvailableNotification object:nil];
		}
		checkSurveyRequest.delegate = nil;
		[checkSurveyRequest release], checkSurveyRequest = nil;
		[parser release], parser = nil;
	}
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)request {
	if (request == checkSurveyRequest) {
		NSLog(@"Survey request failed: %@: %@", request.errorTitle, request.errorMessage);
		checkSurveyRequest.delegate = nil;
		[checkSurveyRequest release], checkSurveyRequest = nil;
	}
}
@end
