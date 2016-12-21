//
//  ApptentiveMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessage.h"
#import "ApptentiveBackend.h"
#import "ApptentiveData.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveMessageSender.h"
#import "NSDictionary+Apptentive.h"
#import "ApptentiveMessageCenterInteraction.h"
#import "ApptentiveFileAttachment.h"


NSString *const ATInteractionMessageCenterEventLabelRead = @"read";


@implementation ApptentiveMessage

@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sentByUser;
@dynamic errorOccurred;
@dynamic errorMessageJSON;
@dynamic sender;
@dynamic customData;
@dynamic hidden;
@dynamic automated;
@dynamic title;
@dynamic body;
@dynamic attachments;

+ (void)clearComposingMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ApptentiveData removeEntitiesNamed:@"ATMessage" withPredicate:fetchPredicate];
	}
}

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Shouldn't call newInstanceWithJSON without context argument");
	return nil;
}

+ (instancetype)messageWithJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context {
	ApptentiveMessage *message = [ApptentiveMessage findMessageWithPendingID:json[@"nonce"] inContext:context];

	if (message == nil) {
		message = [self findMessageWithID:json[@"id"] inContext:context];
	}

	if (message == nil) {
		message = (ApptentiveMessage *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}

	[message updateWithJSON:json];

	// If server creation time is set, overwrite client creation time.
	if (![message isCreationTimeEmpty]) {
		message.clientCreationTime = message.creationTime;
	}

	return message;
}

+ (instancetype)newInstanceWithBody:(NSString *)body attachments:(NSArray *)attachments {
	ApptentiveMessage *result = (ApptentiveMessage *)[ApptentiveData newEntityNamed:@"ATMessage"];

	result.body = body;
	if (attachments) {
		result.attachments = [NSMutableOrderedSet orderedSetWithArray:attachments];
	}

	[result setup];

	return result;
}

+ (ApptentiveMessage *)findMessageWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context {
	ApptentiveMessage *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ApptentiveData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate inContext:context];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ApptentiveMessage *)findMessageWithPendingID:(NSString *)pendingID inContext:(NSManagedObjectContext *)context {
	ApptentiveMessage *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		NSArray *results = [ApptentiveData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate inContext:context];
		if (results && [results count] != 0) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

- (void)setup {
	[super setup];
	if (self.pendingMessageID == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);

		self.pendingMessageID = [NSString stringWithFormat:@"pending-message:%@", (__bridge NSString *)uuidStringRef];

		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	[self setup];
}

- (NSArray *)errorsFromErrorMessage {
	if (self.errorMessageJSON == nil) {
		return nil;
	}

	NSError *error = nil;
	NSObject *errorObject = (NSObject *)[ApptentiveJSONSerialization JSONObjectWithString:self.errorMessageJSON error:&error];

	if (errorObject == nil) {
		ApptentiveLogError(@"Error parsing errors: %@", error);
		return nil;
	}
	if ([errorObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary *errorDictionary = (NSDictionary *)errorObject;
		NSObject *errors = [errorDictionary objectForKey:@"errors"];
		if (errors != nil && [errors isKindOfClass:[NSArray class]]) {
			return [(NSArray *)errors copy];
		}
	}
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];

	NSDictionary *senderDict = [json at_safeObjectForKey:@"sender"];
	if (senderDict != nil) {
		ApptentiveMessageSender *sender = [ApptentiveMessageSender newOrExistingMessageSenderFromJSON:senderDict inContext:self.managedObjectContext];
		[self setValue:sender forKey:@"sender"];
		sender = nil;
	}

	NSNumber *priorityNumber = [json at_safeObjectForKey:@"priority"];
	if (priorityNumber != nil) {
		self.priority = priorityNumber;
	}

	NSString *tmpBody = [json at_safeObjectForKey:@"body"];
	if (tmpBody) {
		self.body = tmpBody;
	}

	NSString *tmpTitle = [json at_safeObjectForKey:@"title"];
	if (tmpTitle) {
		self.title = tmpTitle;
	}

	NSArray *attachmentsJSON = [json at_safeObjectForKey:@"attachments"];
	if ([attachmentsJSON isKindOfClass:[NSArray class]]) {
		if (self.attachments.count == 0) {
			NSMutableOrderedSet *attachments = [NSMutableOrderedSet orderedSetWithCapacity:attachmentsJSON.count];

			for (id tmpAttachment in attachmentsJSON) {
				if ([tmpAttachment isKindOfClass:[NSDictionary class]]) {
					NSDictionary *attachmentJSON = (NSDictionary *)tmpAttachment;
					ApptentiveFileAttachment *attachment = [ApptentiveFileAttachment newInstanceWithJSON:attachmentJSON inContext:self.managedObjectContext];

					if (attachment) {
						[attachments addObject:attachment];
					}
				}
			}

			self.attachments = attachments;
		} else if (self.attachments.count == attachmentsJSON.count) {
			for (NSUInteger i = 0; i < self.attachments.count; i++) {
				ApptentiveFileAttachment *originalAttachment = [self.attachments objectAtIndex:i];
				NSDictionary *newJSON = [attachmentsJSON objectAtIndex:i];
				[originalAttachment updateWithJSON:newJSON];
			}
		} else {
			ApptentiveLogError(@"Mismatch in number of attachments in message (%d) versus API (%d).", self.attachments.count, attachmentsJSON.count);
		}
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.body) {
		result[@"body"] = self.body;
	}
	if (self.automated.boolValue) {
		result[@"automated"] = @YES;
	}
	if (self.pendingMessageID != nil) {
		result[@"nonce"] = self.pendingMessageID;
	}
	if (self.customData) {
		NSDictionary *customDataDictionary = [self dictionaryForCustomData];
		if (customDataDictionary && customDataDictionary.count) {
			result[@"custom_data"] = customDataDictionary;
		}
	}
	if (self.hidden != nil) {
		result[@"hidden"] = self.hidden;
	}

	return result;
}

- (void)setCustomDataValue:(id)value forKey:(NSString *)key {
	NSDictionary *customData = [self dictionaryForCustomData];
	NSMutableDictionary *mutableCustomData = nil;
	if (customData == nil) {
		mutableCustomData = [NSMutableDictionary dictionary];
	} else {
		mutableCustomData = [customData mutableCopy];
	}
	[mutableCustomData setValue:value forKey:key];
	self.customData = [self dataForDictionary:mutableCustomData];
}

- (void)addCustomDataFromDictionary:(NSDictionary *)dictionary {
	NSDictionary *customData = [self dictionaryForCustomData];
	NSMutableDictionary *mutableCustomData = nil;
	if (customData == nil) {
		mutableCustomData = [NSMutableDictionary dictionary];
	} else {
		mutableCustomData = [customData mutableCopy];
	}
	if (dictionary != nil) {
		[mutableCustomData addEntriesFromDictionary:dictionary];
	}
	self.customData = [self dataForDictionary:mutableCustomData];
}

- (NSDictionary *)dictionaryForCustomData {
	if (self.customData == nil) {
		return @{};
	} else {
		NSDictionary *result = nil;
		@try {
			result = [NSKeyedUnarchiver unarchiveObjectWithData:self.customData];
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

- (NSNumber *)creationTimeForSections {
	BOOL distantFutureCreationTime = (self.creationTime.doubleValue > self.clientCreationTime.doubleValue + 365 * 24 * 60 * 60);

	return distantFutureCreationTime ? self.clientCreationTime : self.creationTime;
}

- (void)markAsRead {
	if (![self.seenByUser boolValue]) {
		self.seenByUser = @YES;
		if (self.apptentiveID && ![self.sentByUser boolValue]) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			if (self.apptentiveID) {
				[userInfo setObject:self.apptentiveID forKey:@"message_id"];
			}

			[userInfo setObject:@"CompoundMessage" forKey:@"message_type"];

			[[ApptentiveMessageCenterInteraction interactionForInvokingMessageEvents] engage:ATInteractionMessageCenterEventLabelRead fromViewController:nil userInfo:userInfo];
		}

		// Doing this synchronously triggers Core Data's recursive save detection.
		dispatch_async(dispatch_get_main_queue(), ^{
			[ApptentiveData save];
		});
	}
}

@end


@implementation ApptentiveMessage (QuickLook)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
	return self.attachments.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
	return [self.attachments objectAtIndex:index];
}

@end
