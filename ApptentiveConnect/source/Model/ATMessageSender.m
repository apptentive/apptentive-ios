//
//  ATMessageSender.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessageSender.h"

#import "ATData.h"
#import "NSDictionary+Apptentive.h"


@implementation ATMessageSender

@dynamic apptentiveID;
@dynamic name;
@dynamic emailAddress;
@dynamic profilePhotoURL;
@dynamic sentMessages;
@dynamic receivedMessages;

+ (instancetype)newInstanceWithID:(NSString *)apptentiveID {
	ATMessageSender *result = (ATMessageSender *)[ATData newEntityNamed:@"ATMessageSender"];
	result.apptentiveID = apptentiveID;

	return result;
}

+ (ATMessageSender *)findSenderWithID:(NSString *)apptentiveID {
	ATMessageSender *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ATData findEntityNamed:@"ATMessageSender" withPredicate:fetchPredicate];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ATMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json {
	if (!json) return nil;

	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	if (!apptentiveID) return nil;

	ATMessageSender *sender = [ATMessageSender findSenderWithID:apptentiveID];
	if (!sender) {
		sender = [ATMessageSender newInstanceWithID:apptentiveID];
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
