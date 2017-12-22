//
//  ApptentiveEngagementBackend.m
//  Apptentive
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveEventPayload.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionController.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveSerialRequest.h"
#import "Apptentive_Private.h"
#import "ApptentiveDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

NSString *const ATEngagementCodePointHostAppVendorKey = @"local";
NSString *const ATEngagementCodePointHostAppInteractionKey = @"app";
NSString *const ATEngagementCodePointApptentiveVendorKey = @"com.apptentive";
NSString *const ATEngagementCodePointApptentiveAppInteractionKey = @"app";

NSString *const ApptentiveEngagementMessageCenterEvent = @"show_message_center";
NSString *const ATInteractionTextModalEventLabelInteraction = @"interaction";

@implementation ApptentiveBackend (Engagement)

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event {
	ApptentiveAssertOperationQueue(self.operationQueue);
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

- (void)engageApptentiveAppEvent:(NSString *)event {
	[self engage:event fromInteraction:[ApptentiveInteraction apptentiveAppInteraction] fromViewController:nil];
}

- (void)engageLocalEvent:(NSString *)event userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController {
	[self engageLocalEvent:event userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController completion:nil];
}

- (void)engageLocalEvent:(NSString *)event userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(BOOL engaged))completion {
	[self engage:event fromInteraction:[ApptentiveInteraction localAppInteraction] fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData completion:completion];
}

- (void)engageCodePoint:(NSString *)codePoint fromInteraction:(nullable ApptentiveInteraction *)fromInteraction userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController {
	[self engageCodePoint:codePoint fromInteraction:fromInteraction userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController completion:nil];
}

- (void)engageCodePoint:(NSString *)codePoint fromInteraction:(nullable ApptentiveInteraction *)fromInteraction userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(BOOL engaged))completion {
	ApptentiveLogInfo(@"Engage Apptentive event: %@", codePoint);
	ApptentiveAssertOperationQueue(self.operationQueue);

	// TODO: Do this on the background queue?
	ApptentiveConversation *conversation = self.conversationManager.activeConversation;

	if (conversation == nil) {
		ApptentiveLogWarning(@"Attempting to engage event with no active conversation.");
		if (completion) {
			completion(NO);
		}
		return;
	}

    [self conversation:conversation addMetricWithName:codePoint fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];

	[conversation warmCodePoint:codePoint];
	[conversation engageCodePoint:codePoint];

	BOOL didEngageInteraction = NO;

	ApptentiveEngagementBackend *engagementBackend = [[ApptentiveEngagementBackend alloc] initWithConversation:conversation manifest:self.conversationManager.manifest];

	ApptentiveInteraction *interaction = [engagementBackend interactionForEvent:codePoint];
	if (interaction) {
		ApptentiveLogInfo(@"--Running valid %@ interaction.", interaction.type);

		dispatch_sync(dispatch_get_main_queue(), ^{
			UIViewController *presentingController = viewController;
			if (viewController != nil && (!viewController.isViewLoaded || viewController.view.window == nil)) {
				ApptentiveLogError(@"Attempting to present interaction on a view controller whose view is not visible in a window. Using a separate window instead.");
				presentingController = nil;
			}
			
			[self presentInteraction:interaction fromViewController:presentingController];
		});

		[conversation engageInteraction:interaction.identifier];
		didEngageInteraction = YES;
	}
	
	if (completion) {
		completion(didEngageInteraction);
	}
}

- (void)codePointWasSeen:(NSString *)codePoint {
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation warmCodePoint:codePoint];
}

- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController {
	[self engage:event fromInteraction:interaction fromViewController:viewController userInfo:nil customData:nil extendedData:nil completion:nil];
}

- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo {
	[self engage:event fromInteraction:interaction fromViewController:viewController userInfo:userInfo customData:nil extendedData:nil completion:nil];
}

- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData {
	[self engage:event fromInteraction:interaction fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData completion:nil];
}

- (void)engage:(NSString *)event fromInteraction:(nonnull ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData completion:(void (^ _Nullable)(BOOL))completion {
	ApptentiveAssertNotNil(interaction, @"Attempted to engage event '%@' for nil interaction", event);
	
	if (!self.operationQueue.isCurrent) {
		[self.operationQueue dispatchAsync:^{
			[self engage:event fromInteraction:interaction fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData completion:completion];
		}];
		return;
	}
	
	NSString *codePoint = [interaction codePointForEvent:event];
	
	[self engageCodePoint:codePoint fromInteraction:interaction userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController completion:completion];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation warmInteraction:interactionID];
}

- (void)presentInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController {
	if (!interaction) {
		ApptentiveLogError(@"Attempting to present an interaction that does not exist!");
		return;
	}
	
	// we always need to dispatch this call on the UI-thread since we create and present
	// view controllers here
	if (![NSThread isMainThread]) {
		dispatch_sync(dispatch_get_main_queue(), ^{
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

- (void)conversation:(ApptentiveConversation *)conversation addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData {
	ApptentiveAssertOperationQueue(self.operationQueue);

	if (self.configuration.metricsEnabled == NO || name == nil || conversation.state == ApptentiveConversationStateLoggedOut) {
		return;
	}

	ApptentiveEventPayload *payload = [[ApptentiveEventPayload alloc] initWithLabel:name creationDate:[NSDate date]];
	payload.interactionIdentifier = fromInteraction.identifier;
	payload.userInfo = userInfo;
	payload.customData = customData;
	payload.extendedData = extendedData;

	[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.managedObjectContext];

	[self processQueuedRecords];
}

- (void)invokeAction:(NSDictionary *)actionConfig withInteraction:(ApptentiveInteraction *)sourceInteraction fromViewController:(UIViewController *)fromViewController {
	[self.operationQueue dispatchAsync:^{
		ApptentiveInteraction *interaction = nil;
		NSArray *invocations = actionConfig[@"invokes"];

		if (invocations) {
			// TODO: Do this on the background queue?
			interaction = [self interactionForInvocations:invocations];
		}

		NSDictionary *userInfo = @{ @"label": (actionConfig[@"label"] ?: [NSNull null]),
									@"position": (actionConfig[@"position"] ?: [NSNull null]),
									@"invoked_interaction_id": (interaction.identifier ?: [NSNull null]),
									@"action_id": (actionConfig[@"id"] ?: [NSNull null]),
									};

		[self engage:ATInteractionTextModalEventLabelInteraction fromInteraction:sourceInteraction fromViewController:fromViewController userInfo:userInfo];

		if (interaction != nil) {
			[self presentInteraction:interaction fromViewController:fromViewController];
		}
	}];
}

@end

NS_ASSUME_NONNULL_END
