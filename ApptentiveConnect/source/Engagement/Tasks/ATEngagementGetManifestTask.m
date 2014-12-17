//
//  ATEngagementGetManifestTask.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementGetManifestTask.h"
#import "ATBackend.h"
#import "ATDeviceUpdater.h"
#import "ATWebClient+EngagementAdditions.h"
#import "ATEngagementManifestParser.h"
#import "ATEngagementBackend.h"

@interface ATEngagementGetManifestTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATEngagementGetManifestTask
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
		ATLogDebug(@"Failed to download Apptentive configuration because API key is not set!");
		return NO;
	}
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	if ([ATDeviceUpdater shouldUpdate]) {
		// Interactions may depend on device attributes.
		return NO;
	}
	
	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	self.failureOkay = YES;
	if (checkManifestRequest == nil) {
		ATWebClient *client = [ATWebClient sharedClient];
		checkManifestRequest = [[client requestForGettingEngagementManifest] retain];
		checkManifestRequest.delegate = self;
		self.inProgress = YES;
		[checkManifestRequest start];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (checkManifestRequest) {
		checkManifestRequest.delegate = nil;
		[checkManifestRequest cancel];
		[checkManifestRequest release], checkManifestRequest = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (checkManifestRequest) {
		return [checkManifestRequest percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"engagement manifest check";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		if (request == checkManifestRequest) {
			ATEngagementManifestParser *parser = [[ATEngagementManifestParser alloc] init];
			
			NSDictionary *targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:(NSData *)result];
			NSDictionary *targets = targetsAndInteractions[@"targets"];
			NSDictionary *interactions = targetsAndInteractions[@"interactions"];
			
			if (targets && interactions) {
				[[ATEngagementBackend sharedBackend] didReceiveNewTargets:targets andInteractions:interactions maxAge:[request expiresMaxAge]];
			} else {
				ATLogError(@"An error occurred parsing the engagement manifest: %@", [parser parserError]);
			}

			checkManifestRequest.delegate = nil;
			[checkManifestRequest release], checkManifestRequest = nil;
			[parser release], parser = nil;
			self.finished = YES;
		}
		[self release];
	}
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)request {
    @synchronized(self) {
		[self retain];
		if (request == checkManifestRequest) {
			ATLogError(@"Engagement manifest request failed: %@: %@", request.errorTitle, request.errorMessage);
			self.lastErrorTitle = request.errorTitle;
			self.lastErrorMessage = request.errorMessage;
			self.failed = YES;
			[self stop];
		}
		[self release];
	}
}
@end

@implementation ATEngagementGetManifestTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end

