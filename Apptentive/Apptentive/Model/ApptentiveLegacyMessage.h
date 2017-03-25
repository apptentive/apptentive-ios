//
//  ApptentiveLegacyMessage.h
//  Apptentive
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <QuickLook/QuickLook.h>

#import "ApptentiveJSONModel.h"
#import "ApptentiveRecord.h"

typedef NS_ENUM(NSInteger, ATPendingMessageState) {
	ATPendingMessageStateNone = -1,
	ATPendingMessageStateComposing = 0,
	ATPendingMessageStateSending,
	ATPendingMessageStateConfirmed,
	ATPendingMessageStateError
};

@class ATMessageDisplayType, ApptentiveLegacyMessageSender;


@interface ApptentiveLegacyMessage : ApptentiveRecord <ApptentiveJSONModel>

@property (copy, nonatomic) NSString *pendingMessageID;
@property (strong, nonatomic) NSNumber *pendingState;
@property (strong, nonatomic) NSNumber *priority;
@property (strong, nonatomic) NSNumber *seenByUser;
@property (strong, nonatomic) NSNumber *sentByUser;
@property (strong, nonatomic) NSNumber *errorOccurred;
@property (copy, nonatomic) NSString *errorMessageJSON;
@property (strong, nonatomic) ApptentiveLegacyMessageSender *sender;
@property (copy, nonatomic) NSData *customData;
@property (strong, nonatomic) NSNumber *hidden;
@property (strong, nonatomic) NSNumber *automated;
@property (copy, nonatomic) NSString *body;
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) NSOrderedSet *attachments;

+ (void)enqueueUnsentMessagesInContext:(NSManagedObjectContext *)context;

+ (instancetype)newInstanceWithBody:(NSString *)body attachments:(NSArray *)attachments;
+ (void)clearComposingMessages;
+ (instancetype)findMessageWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context;
+ (instancetype)findMessageWithPendingID:(NSString *)pendingID inContext:(NSManagedObjectContext *)context;
+ (instancetype)messageWithJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context;
+ (instancetype)messageWithJSON:(NSDictionary *)json;
- (NSArray *)errorsFromErrorMessage;

@end


@interface ApptentiveLegacyMessage (CoreDataGeneratedAccessors)

- (void)setCustomDataValue:(id)value forKey:(NSString *)key;
- (void)addCustomDataFromDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryForCustomData;
- (NSData *)dataForDictionary:(NSDictionary *)dictionary;

- (NSNumber *)creationTimeForSections;

- (void)markAsRead;

@end


@interface ApptentiveLegacyMessage (QuickLook) <QLPreviewControllerDataSource>
@end
