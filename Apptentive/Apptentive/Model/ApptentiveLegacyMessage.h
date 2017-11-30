//
//  ApptentiveLegacyMessage.h
//  Apptentive
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATPendingMessageState) {
	ATPendingMessageStateNone = -1,
	ATPendingMessageStateComposing = 0,
	ATPendingMessageStateSending,
	ATPendingMessageStateConfirmed,
	ATPendingMessageStateError
};

@class ATMessageDisplayType, ApptentiveLegacyMessageSender, ApptentiveConversation;


@interface ApptentiveLegacyMessage : ApptentiveRecord

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

+ (void)enqueueUnsentMessagesInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation oldAttachmentPath:(NSString *)oldAttachmentPath newAttachmentPath:(NSString *)newAttachmentPath;

@end

NS_ASSUME_NONNULL_END
