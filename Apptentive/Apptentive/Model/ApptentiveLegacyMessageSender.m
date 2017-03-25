//
//  ApptentiveLegacyMessageSender.m
//  Apptentive
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyMessageSender.h"

#import "ApptentiveData.h"
#import "NSDictionary+Apptentive.h"


@implementation ApptentiveLegacyMessageSender

@dynamic apptentiveID;
@dynamic name;
@dynamic emailAddress;
@dynamic profilePhotoURL;
@dynamic sentMessages;
@dynamic receivedMessages;

+ (instancetype)newInstanceWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context {
	ApptentiveLegacyMessageSender *result = (ApptentiveLegacyMessageSender *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessageSender" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

	result.apptentiveID = apptentiveID;

	return result;
}

+ (ApptentiveLegacyMessageSender *)findSenderWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context {
	ApptentiveLegacyMessageSender *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ApptentiveData findEntityNamed:@"ATMessageSender" withPredicate:fetchPredicate inContext:context];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ApptentiveLegacyMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context {
	if (!json) return nil;

	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	if (!apptentiveID) return nil;

	ApptentiveLegacyMessageSender *sender = [ApptentiveLegacyMessageSender findSenderWithID:apptentiveID inContext:context];
	if (!sender) {
		sender = [ApptentiveLegacyMessageSender newInstanceWithID:apptentiveID inContext:context];
	}

	NSString *senderEmail = [json at_safeObjectForKey:@"email"];
	if (senderEmail) {
		sender.emailAddress = senderEmail;
	}

	NSString *senderName = [json at_safeObjectForKey:@"name"];
	if (senderName) {
		sender.name = senderName;
	}

	NSString *profilePhoto = [json at_safeObjectForKey:@"profile_photo"];
	if (profilePhoto) {
		sender.profilePhotoURL = profilePhoto;
	}

	return sender;
}

- (NSDictionary *)apiJSON {
	return @{ @"email": self.emailAddress,
		@"id": self.apptentiveID,
		@"name": self.name };
}
@end
