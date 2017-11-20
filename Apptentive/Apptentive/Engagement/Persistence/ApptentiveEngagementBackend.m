//
//  ApptentiveEngagementBackend.m
//  Apptentive
//
//  Created by Alex Lementuev on 6/26/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementBackend.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionController.h"
#import "ApptentiveInteractionInvocation.h"
#import "Apptentive_Private.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveEngagementBackend

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation manifest:(ApptentiveEngagementManifest *)manifest {
	self = [super init];
	if (self) {
		// TODO: check for nil
		_conversation = conversation;
		_manifest = manifest;
	}
	return self;
}

- (nullable ApptentiveInteraction *)interactionForEvent:(NSString *)event {
	NSArray *invocations = self.manifest.targets[event];
	ApptentiveInteraction *interaction = [self interactionForInvocations:invocations];

	return interaction;
}

- (nullable ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations {
	NSString *interactionID = nil;

	for (NSObject *invocationOrDictionary in invocations) {
		ApptentiveInteractionInvocation *invocation = nil;

		// Allow parsing of ATInteractionInvocation and NSDictionary invocation objects
		if ([invocationOrDictionary isKindOfClass:[ApptentiveInteractionInvocation class]]) {
			invocation = (ApptentiveInteractionInvocation *)invocationOrDictionary;
		} else if ([invocationOrDictionary isKindOfClass:[NSDictionary class]]) {
			invocation = [ApptentiveInteractionInvocation invocationWithJSONDictionary:((NSDictionary *)invocationOrDictionary)];
		} else {
			ApptentiveLogError(@"Attempting to parse an invocation that is neither an ATInteractionInvocation or NSDictionary.");
		}

		if (invocation && [invocation isKindOfClass:[ApptentiveInteractionInvocation class]]) {
			if ([invocation criteriaAreMetForConversation:self.conversation]) {
				interactionID = invocation.interactionID;
				break;
			}
		}
	}

	ApptentiveInteraction *interaction = nil;
	if (interactionID) {
		interaction = [self interactionForIdentifier:interactionID];
	}

	return interaction;
}

- (ApptentiveInteraction *)interactionForIdentifier:(NSString *)identifier {
	return self.manifest.interactions[identifier];
}

@end

NS_ASSUME_NONNULL_END
