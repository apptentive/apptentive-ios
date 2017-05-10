//
//  ApptentiveLegacyEvent.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"
#import "ApptentiveLegacyEvent.h"
#import "ApptentiveSerialRequest.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEventPayload.h"


@implementation ApptentiveLegacyEvent

@dynamic pendingEventID;
@dynamic dictionaryData;
@dynamic label;

+ (void)enqueueUnsentEventsInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(context, @"Context is nil");
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATEvent"];

	NSError *error;
	NSArray *unsentEvents = [context executeFetchRequest:request error:&error];

	if (unsentEvents == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent events: %@", error);
		return;
	}

	for (ApptentiveLegacyEvent *event in unsentEvents) {
		ApptentiveEventPayload *payload = [[ApptentiveEventPayload alloc] initWithLabel:event.label];
		ApptentiveAssertNotNil(payload, @"Failed to create an event payload");

		// TODO: Add custom data, extended data, and/or interaction ID?
		if (payload != nil) {
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:context];
		}

		[context deleteObject:event];
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.label != nil) {
		result[@"label"] = self.label;
	}
	if (self.dictionaryData) {
		NSDictionary *dictionary = [self dictionaryForCurrentData];
		[result addEntriesFromDictionary:dictionary];
	}

	if (self.pendingEventID != nil) {
		result[@"nonce"] = self.pendingEventID;
	}

	// Monitor that the Event payload has not been dropped on retry
	if (!result) {
		ApptentiveLogError(@"Event json should not be nil.");
	}
	if (result.count == 0) {
		ApptentiveLogError(@"Event json should return a result.");
	}
	if (!result[@"label"]) {
		ApptentiveLogError(@"Event json should include a `label`.");
		return nil;
	}
	if (!result[@"nonce"]) {
		ApptentiveLogError(@"Event json should include a `nonce`.");
		return nil;
	}

	NSDictionary *apiJSON = @{ @"event": result };

	return apiJSON;
}

//- (void)addEntriesFromDictionary:(NSDictionary *)incomingDictionary {
//	NSDictionary *dictionary = [self dictionaryForCurrentData];
//	NSMutableDictionary *mutableDictionary = nil;
//	if (dictionary == nil) {
//		mutableDictionary = [NSMutableDictionary dictionary];
//	} else {
//		mutableDictionary = [dictionary mutableCopy];
//	}
//	if (incomingDictionary != nil) {
//		[mutableDictionary addEntriesFromDictionary:incomingDictionary];
//	}
//	[self setDictionaryData:[self dataForDictionary:mutableDictionary]];
//}
//
#pragma mark Private
- (NSDictionary *)dictionaryForCurrentData {
	if (self.dictionaryData == nil) {
		return @{};
	} else {
		NSDictionary *result = nil;
		@try {
			result = [NSKeyedUnarchiver unarchiveObjectWithData:self.dictionaryData];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to unarchive event: %@", exception);
		}
		return result;
	}
}

- (NSData *)dataForDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		return nil;
	} else {
		return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	}
}

@end
