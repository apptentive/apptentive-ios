//
//  ATActivityFeedUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConversationUpdater.h"

#import "ATBackend.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";

@interface ATConversationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed;
@end

@implementation ATConversationUpdater
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATConversationUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)createConversation {
	[self cancel];
	ATConversation *conversation = [[ATConversation alloc] init];
	conversation.deviceID = [[ATBackend sharedBackend] deviceUUID];
	request = [[[ATWebClient sharedClient] requestForCreatingConversation:conversation] retain];
	request.delegate = self;
	[request start];
	[conversation release], conversation = nil;
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

+ (BOOL)conversationExists {
	ATConversation *currentFeed = [ATConversationUpdater currentConversation];
	if (currentFeed == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATConversation *)currentConversation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *conversationData = [defaults dataForKey:ATCurrentConversationPreferenceKey];
	if (!conversationData) {
		return nil;
	}
	ATConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithData:conversationData];
	return conversation;
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			ATLogError(@"Activity feed result is not NSDictionary!");
			[delegate conversation:self createdSuccessfully:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[delegate conversation:self createdSuccessfully:NO];
	}
}

@end


@implementation ATConversationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed {
	ATConversation *conversation = (ATConversation *)[ATConversation newInstanceWithJSON:jsonActivityFeed];
	if (conversation) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *conversationData = [NSKeyedArchiver archivedDataWithRootObject:conversation];
		[defaults setObject:conversationData forKey:ATCurrentConversationPreferenceKey];
		[defaults synchronize];
		[delegate conversation:self createdSuccessfully:YES];
	} else {
		[delegate conversation:self createdSuccessfully:NO];
	}
	[conversation release], conversation = nil;
}
@end
