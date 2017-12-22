//
//  ApptentiveMessage.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

NS_ASSUME_NONNULL_BEGIN

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


@interface ApptentiveMessage : NSObject <NSSecureCoding, NSCopying>

@property (readonly, nullable, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *localIdentifier;
@property (readonly, nonatomic) NSDate *sentDate;
@property (readonly, nullable, nonatomic) NSArray *attachments;
@property (strong, nullable, nonatomic) ApptentiveMessageSender *sender;
@property (readonly, nullable, nonatomic) NSString *body;
@property (assign, nonatomic) ApptentiveMessageState state;
@property (readonly, nonatomic) BOOL automated;
@property (readonly, nullable, nonatomic) NSDictionary *customData;
@property (readonly, nonatomic) BOOL inbound;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;
- (nullable instancetype)initWithBody:(nullable NSString *)body attachments:(nullable NSArray *)attachments automated:(BOOL)automated customData:(NSDictionary *_Nullable)customData creationDate:(NSDate *)creationDate;

- (ApptentiveMessage *)mergedWith:(ApptentiveMessage *)messageFromServer;
- (void)updateWithLocalIdentifier:(NSString *)localIdentifier;

@end


@interface ApptentiveMessage (QuickLook) <QLPreviewControllerDataSource>
@end

NS_ASSUME_NONNULL_END
