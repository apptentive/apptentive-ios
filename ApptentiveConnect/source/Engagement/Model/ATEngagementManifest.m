//
//  ATEngagementManifest.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementManifest.h"
#import "ATJSONSerialization.h"
#import "ATInteraction.h"
#import "ATInteractionInvocation.h"

@implementation ATEngagementManifest

- (instancetype)init
{
	self = [super init];
	if (self) {
		_targets = @{};
		_interactions = @{};
	}
	return self;
}

+ (instancetype)newInstanceFromDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];

	if (self) {
		NSMutableDictionary *targets = [NSMutableDictionary dictionary];
		NSMutableDictionary *interactions = [NSMutableDictionary dictionary];

		BOOL success = NO;

		@try {
			// Targets
			NSDictionary *targetsDictionary = dictionary[@"targets"];
			for (NSString *event in [targetsDictionary allKeys]) {
				NSArray *invocationsJSONArray = targetsDictionary[event];
				NSArray *invocationsArray = [ATInteractionInvocation invocationsWithJSONArray:invocationsJSONArray];
				[targets setObject:invocationsArray forKey:event];
			}

			// Interactions
			NSArray *interactionsArray = dictionary[@"interactions"];
			for (NSDictionary *interactionDictionary in interactionsArray) {
				ATInteraction *interactionObject = [ATInteraction interactionWithJSONDictionary:interactionDictionary];
				[interactions setObject:interactionObject forKey:interactionObject.identifier];
			}

			success = YES;
		}
		@catch (NSException *exception) {
			ATLogError(@"Exception parsing engagement manifest: %@", exception);

			success = NO;
		}

		if (success) {
			_targets = targets;
			_interactions = interactions;
		} else {
			return nil;
		}
	}
	
	return self;
}

// Included for completeness of the ATUpdatable protocol
- (NSDictionary *)dictionaryRepresentation {
	return @{ @"targets" : self.targets, @"interactions": self.interactions };
}

- (instancetype)initWithTargets:(NSDictionary *)targets interactions:(NSDictionary *)interactions {
	self = [super init];

	if (self) {
		_targets = targets;
		_interactions = interactions;
	}

	return self;
}

@end
