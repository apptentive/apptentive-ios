//
//  ApptentiveMessageSender.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageSender.h"

#import "ApptentiveData.h"
#import "NSDictionary+Apptentive.h"


@implementation ApptentiveMessageSender

@dynamic apptentiveID;
@dynamic name;
@dynamic emailAddress;
@dynamic profilePhotoURL;
@dynamic sentMessages;
@dynamic receivedMessages;

+ (instancetype)newInstanceWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context {
	ApptentiveMessageSender *result = (ApptentiveMessageSender *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessageSender" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

	result.apptentiveID = apptentiveID;

	return result;
}

+ (ApptentiveMessageSender *)findSenderWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context {
	ApptentiveMessageSender *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ApptentiveData findEntityNamed:@"ATMessageSender" withPredicate:fetchPredicate inContext:context];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ApptentiveMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context {
	if (!json) return nil;

	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	if (!apptentiveID) return nil;

	ApptentiveMessageSender *sender = [ApptentiveMessageSender findSenderWithID:apptentiveID inContext:context];
	if (!sender) {
		sender = [ApptentiveMessageSender newInstanceWithID:apptentiveID inContext:context];
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
