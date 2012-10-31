//
//  ATMessageSender.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessageSender.h"

#import "ATData.h"
#import "ATMessage.h"

@implementation ATMessageSender

@dynamic apptentiveID;
@dynamic name;
@dynamic emailAddress;
@dynamic sentMessages;
@dynamic receivedMessages;


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
	
	NSString *apptentiveID = [json objectForKey:@"id"];
	if (!apptentiveID) return nil;
	
	ATMessageSender *sender = [ATMessageSender findSenderWithID:apptentiveID];
	if (!sender) {
		sender = (ATMessageSender *)[ATData newEntityNamed:@"ATMessageSender"];
		sender.apptentiveID = apptentiveID;
	} else {
		[sender retain];
	}
	NSString *senderEmail = [json objectForKey:@"email"];
	NSString *senderName = [json objectForKey:@"name"];
	if (senderEmail) {
		sender.emailAddress = senderEmail;
	}
	if (senderName) {
		sender.name = senderName;
	}
	return sender;
}

- (NSDictionary *)apiJSON {
	return @{@"email":self.emailAddress, @"id":self.apptentiveID, @"name":self.name};
}
@end
