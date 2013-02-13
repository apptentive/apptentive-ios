//
//  ATMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessage.h"

#import "ATBackend.h"
#import "ATData.h"
#import "ATMessageDisplayType.h"
#import "ATMessageSender.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATMessage

@dynamic apptentiveID;
@dynamic clientCreationTime;
@dynamic clientCreationTimezone;
@dynamic clientCreationUTCOffset;
@dynamic creationTime;
@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sentByUser;
@dynamic sender;
@dynamic displayTypes;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

+ (ATMessage *)findMessageWithID:(NSString *)apptentiveID {
	ATMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ATData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ATMessage *)findMessageWithPendingID:(NSString *)pendingID {
	ATMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		NSArray *results = [ATData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate];
		if (results && [results count] != 0) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

- (void)setup {
	if (self.clientCreationTime == nil || [self.clientCreationTime doubleValue] == 0) {
		[self updateClientCreationTime];
	}
	if (self.creationTime == nil || [self.creationTime doubleValue] == 0) {
		self.creationTime = self.clientCreationTime;
	}
	if (self.pendingMessageID == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		self.pendingMessageID = [NSString stringWithFormat:@"pending-message:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
}

- (void)updateClientCreationTime {
	self.clientCreationTime = [NSNumber numberWithDouble:(double)[[NSDate date] timeIntervalSince1970]];
	self.creationTime = self.clientCreationTime;
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	[self setup];
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSDictionary *senderDict = [json at_safeObjectForKey:@"sender"];
	if (senderDict != nil) {
		ATMessageSender *sender = [ATMessageSender newOrExistingMessageSenderFromJSON:senderDict];
		[self setValue:sender forKey:@"sender"];
		[sender release], sender = nil;
	}
	NSString *tmpID = [json at_safeObjectForKey:@"id"];
	if (tmpID != nil) {
		self.apptentiveID = tmpID;
	}
	
	ATMessageDisplayType *messageCenterType = [ATMessageDisplayType messageCenterType];
	ATMessageDisplayType *modalType = [ATMessageDisplayType modalType];
	
	NSObject *createdAt = [json at_safeObjectForKey:@"created_at"];
	if ([createdAt isKindOfClass:[NSNumber class]]) {
		NSTimeInterval creationTimestamp = [ATMessage timeIntervalForServerTime:(NSNumber *)createdAt];
		self.creationTime = @(creationTimestamp);
	} else if ([createdAt isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)createdAt;
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		self.creationTime = creationTimestamp;
	}
	if (self.clientCreationTime == nil && self.creationTime != nil) {
		self.clientCreationTime = self.creationTime;
	}
	
	NSNumber *priorityNumber = [json at_safeObjectForKey:@"priority"];
	if (priorityNumber != nil) {
		self.priority = priorityNumber;
	}
	
	NSArray *displayTypes = [json at_safeObjectForKey:@"display"];
	BOOL inserted = NO;
	for (NSString *displayType in displayTypes) {
		if ([displayType isEqualToString:@"modal"]) {
			[self addDisplayTypesObject:modalType];
			inserted = YES;
		} else if ([displayType isEqualToString:@"message center"]) {
			[self addDisplayTypesObject:messageCenterType];
			inserted = YES;
		}
	}
	if (!inserted) {
		[self addDisplayTypesObject:messageCenterType];
	}
}

+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp {
	long long serverTimestamp = [timestamp longLongValue];
	NSTimeInterval clientTimestamp = ((double)serverTimestamp)/1000.0;
	return clientTimestamp;
}

+ (NSNumber *)serverFormatForTimeInterval:(NSTimeInterval)timestamp {
	return @((long long)(timestamp * 1000));
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (self.pendingMessageID != nil) {
		result[@"nonce"] = self.pendingMessageID;
	}
	if (self.clientCreationTime != nil) {
		result[@"client_created_at"] = [ATMessage serverFormatForTimeInterval:(NSTimeInterval)[self.clientCreationTime doubleValue]];
	}
	if (self.clientCreationTimezone != nil) {
		result[@"client_created_at_timezone"] = self.clientCreationTimezone;
	}
	if (self.clientCreationUTCOffset != nil) {
		result[@"client_created_at_utc_offset"] = self.clientCreationUTCOffset;
	}
	return result;
}
@end
