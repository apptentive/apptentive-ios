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

@interface ApptentiveMessage : NSObject

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *localIdentifier;
@property (readonly, nonatomic) NSDate *sentDate;
@property (readonly, nonatomic) NSArray *attachments;
@property (readonly, nonatomic) ApptentiveMessageSender *sender;
@property (readonly, nonatomic) NSString *body;
@property (assign, nonatomic) ApptentiveMessageState state;
@property (readonly, nonatomic) BOOL automated;
@property (readonly, nonatomic) NSDictionary *customData;

- (instancetype)initWithJSON:(NSDictionary *)JSON;
- (instancetype)initWithBody:(NSString *)body attachments:(NSArray *)attachments senderIdentifier:(NSString *)senderIdentifier automated:(BOOL)automated customData:(NSDictionary *)customData;

- (ApptentiveMessage *)mergedWith:(ApptentiveMessage *)messageFromServer;
- (void)updateWithLocalIdentifier:(NSString *)localIdentifier;

@end

@interface ApptentiveMessage (QuickLook) <QLPreviewControllerDataSource>
@end
