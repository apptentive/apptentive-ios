//
//  ApptentiveEngagementBackend.m
//  Apptentive
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "Apptentive_Private.h"
#import "ApptentiveInteractionController.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveEventPayload.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveAppConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

NSString *const ATEngagementCodePointHostAppVendorKey = @"local";
NSString *const ATEngagementCodePointHostAppInteractionKey = @"app";
NSString *const ATEngagementCodePointApptentiveVendorKey = @"com.apptentive";
NSString *const ATEngagementCodePointApptentiveAppInteractionKey = @"app";

NSString *const ApptentiveEngagementMessageCenterEvent = @"show_message_center";


@implementation ApptentiveBackend (Engagement)

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event {
	NSString *codePoint = [[ApptentiveInteraction localAppInteraction] codePointForEvent:event];

	return [self canShowInteractionForCodePoint:codePoint];
}

- (BOOL)canShowInteractionForCodePoint:(NSString *)codePoint {
	ApptentiveInteraction *interaction = [self interactionForEvent:codePoint];

	return (interaction != nil);
}

- (ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations {
	ApptentiveEngagementBackend *engagementBackend = [[ApptentiveEngagementBackend alloc] initWithConversation:self.conversationManager.activeConversation manifest:self.conversationManager.manifest];
	return [engagementBackend interactionForInvocations:invocations];
}

- (ApptentiveInteraction *)interactionForIdentifier:(NSString *)identifier {
	return self.conversationManager.manifest.interactions[identifier];
}

- (ApptentiveInteraction *)interactionForEvent:(NSString *)event {
	NSArray *invocations = self.conversationManager.manifest.targets[event];
	ApptentiveInteraction *interaction = [self interactionForInvocations:invocations];

	return interaction;
}

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string {
	// Only escape "%", "/", and "#".
	// Do not change unless the server spec changes.
	NSMutableString *escape = [string mutableCopy];
	[escape replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];

	return escape;
}

+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event {
	NSString *encodedVendor = [[self class] stringByEscapingCodePointSeparatorCharactersInString:vendor];
	NSString *encodedInteractionType = [[self class] stringByEscapingCodePointSeparatorCharactersInString:interactionType];
	NSString *encodedEvent = [[self class] stringByEscapingCodePointSeparatorCharactersInString:event];

	NSString *codePoint = [NSString stringWithFormat:@"%@#%@#%@", encodedVendor, encodedInteractionType, encodedEvent];

	return codePoint;
}

- (BOOL)engageApptentiveAppEvent:(NSString *)event {
	return [[ApptentiveInteraction apptentiveAppInteraction] engage:event fromViewController:nil];
}

- (BOOL)engageLocalEvent:(NSString *)event userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController {
	return [[ApptentiveInteraction localAppInteraction] engage:event fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData];
}

- (BOOL)engageCodePoint:(NSString *)codePoint fromInteraction:(nullable ApptentiveInteraction *)fromInteraction userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController {
	if (self.state != ApptentiveBackendStatePayloadDatabaseAvailable) {
		[self.operationQueue addOperationWithBlock:^{
			[self engageCodePoint:codePoint fromInteraction:fromInteraction userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController];
		}];

		ApptentiveLogInfo(@"Backend not ready. Deferring engagement of %@", codePoint);
		return NO;
	}

	ApptentiveLogInfo(@"Engage Apptentive event: %@", codePoint);

	// TODO: Do this on the background queue?
	ApptentiveConversation *conversation = self.conversationManager.activeConversation;

	if (conversation == nil) {
		ApptentiveLogWarning(@"Attempting to engage event with no active conversation.");
		return NO;
	}

	[self.operationQueue addOperationWithBlock:^{
        [self conversation:conversation addMetricWithName:codePoint fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];
	}];

	// FIXME: Race condition when trying to modify and save conversation from different threads
	@synchronized(conversation) {
		[conversation warmCodePoint:codePoint];
		[conversation engageCodePoint:codePoint];
	}

	BOOL didEngageInteraction = NO;

	ApptentiveEngagementBackend *engagementBackend = [[ApptentiveEngagementBackend alloc] initWithConversation:conversation manifest:self.conversationManager.manifest];

	ApptentiveInteraction *interaction = [engagementBackend interactionForEvent:codePoint];
	if (interaction) {
		ApptentiveLogInfo(@"--Running valid %@ interaction.", interaction.type);
		
		if (viewController != nil && (!viewController.isViewLoaded || viewController.view.window == nil)) {
			ApptentiveLogError(@"Attempting to present interaction on a view controller whose view is not visible in a window. Using a separate window instead.");
			viewController = nil;
		}

		[self presentInteraction:interaction fromViewController:viewController];

		[conversation engageInteraction:interaction.identifier];
		didEngageInteraction = YES;
	}

	return didEngageInteraction;
}

- (void)codePointWasSeen:(NSString *)codePoint {
	// TODO: Do this on the background queue?
	[self.conversationManager.activeConversation warmCodePoint:codePoint];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	// TODO: Do this on the background queue?
	[self.conversationManager.activeConversation warmInteraction:interactionID];
}

- (void)presentInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController {
	if (!interaction) {
		ApptentiveLogError(@"Attempting to present an interaction that does not exist!");
		return;
	}

	if (![[NSThread currentThread] isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self presentInteraction:interaction fromViewController:viewController];
		});
		return;
	}

	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
		// Only present interaction UI in Active state.
		return;
	}

	ApptentiveInteractionController *controller = [ApptentiveInteractionController interactionControllerWithInteraction:interaction];

	[controller presentInteractionFromViewController:viewController];
}

- (void)conversation:(ApptentiveConversation *)conversation addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	ApptentiveAssertOperationQueue(self.operationQueue);

	if (self.configuration.metricsEnabled == NO || name == nil || conversation.state == ApptentiveConversationStateLoggedOut) {
		return;
	}

	ApptentiveEventPayload *payload = [[ApptentiveEventPayload alloc] initWithLabel:name];
	payload.interactionIdentifier = fromInteraction.identifier;
	payload.userInfo = userInfo;
	payload.customData = customData;
	payload.extendedData = extendedData;

	[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.managedObjectContext];

	[self processQueuedRecords];
}

@end

NS_ASSUME_NONNULL_END
