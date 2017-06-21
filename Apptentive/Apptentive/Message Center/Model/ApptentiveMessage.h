//
//  ApptentiveMessage.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@class ApptentiveMessageSender;

typedef NS_ENUM(NSInteger, ApptentiveMessageState) {
	ApptentiveMessageStateUndefined = 0,
	ApptentiveMessageStatePending,
	ApptentiveMessageStateWaiting,
	ApptentiveMessageStateSending,
	ApptentiveMessageStateSent,
	ApptentiveMessageStateFailedToSend,
	ApptentiveMessageStateUnread,
	ApptentiveMessageStateRead,
	ApptentiveMessageStateHidden
};

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessage : NSObject <NSSecureCoding>

@property (readonly, nullable, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *localIdentifier;
@property (readonly, nonatomic) NSDate *sentDate;
@property (readonly, nullable, nonatomic) NSArray *attachments;
@property (readonly, nullable, nonatomic) ApptentiveMessageSender *sender;
@property (readonly, nullable, nonatomic) NSString *body;
@property (assign, nonatomic) ApptentiveMessageState state;
@property (readonly, nonatomic) BOOL automated;
@property (readonly, nullable, nonatomic) NSDictionary *customData;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;
- (nullable instancetype)initWithBody:(nullable NSString *)body attachments:(nullable NSArray *)attachments senderIdentifier:(NSString *)senderIdentifier automated:(BOOL)automated customData:(NSDictionary *_Nullable)customData;
- (instancetype)initWithBody:(NSString *)body attachments:(NSArray *)attachments sender:(ApptentiveMessageSender *)sender automated:(BOOL)automated customData:(NSDictionary *)customData;

- (ApptentiveMessage *)mergedWith:(ApptentiveMessage *)messageFromServer;
- (void)updateWithLocalIdentifier:(NSString *)localIdentifier;

@end

NS_ASSUME_NONNULL_END


@interface ApptentiveMessage (QuickLook) <QLPreviewControllerDataSource>
@end
