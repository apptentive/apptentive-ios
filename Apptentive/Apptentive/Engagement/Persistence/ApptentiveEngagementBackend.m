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
#import "Apptentive_Private.h"
#import "ApptentiveInteractionController.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveTargets.h"
#import "ApptentiveInteractionController.h"
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
	NSString *interactionIdentifier = [self.manifest.targets interactionIdentifierForEvent:event conversation:self.conversation];

	return self.manifest.interactions[interactionIdentifier];
}

@end

NS_ASSUME_NONNULL_END
