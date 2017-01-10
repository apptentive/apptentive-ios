//
//  ApptentiveSession.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentivePerson, ApptentiveDevice, ApptentiveSDK, ApptentiveAppRelease, ApptentiveEngagement, ApptentiveMutablePerson, ApptentiveMutableDevice, ApptentiveVersion;
@protocol ApptentiveSessionDelegate;

@interface ApptentiveSession : ApptentiveState

@property (readonly, nonatomic) ApptentiveAppRelease *appRelease;
@property (readonly, nonatomic) ApptentiveSDK *SDK;
@property (readonly, nonatomic) ApptentivePerson *person;
@property (readonly, nonatomic) ApptentiveDevice *device;
@property (readonly, nonatomic) ApptentiveEngagement *engagement;
@property (readonly, nonatomic) NSString *APIKey;
@property (readonly, nonatomic) NSString *token;
@property (readonly, nonatomic) NSString *lastMessageID;
@property (readonly, nonatomic) NSDate *currentTime;
@property (readonly, nonatomic) NSMutableDictionary *userInfo;

@property (weak, nonatomic) id<ApptentiveSessionDelegate> delegate;

- (instancetype)initWithAPIKey:(NSString *)APIKey;

- (void)setToken:(NSString *)token personID:(NSString *)personID deviceID:(NSString *)deviceID;

- (void)checkForDiffs;

- (void)updatePerson:(void(^)(ApptentiveMutablePerson *))personUpdateBlock;
- (void)updateDevice:(void(^)(ApptentiveMutableDevice *))deviceUpdateBlock;

- (void)didOverrideStyles;
- (void)didDownloadMessagesUpTo:(NSString *)lastMessageID;

@property (readonly, nonatomic) NSDictionary *conversationCreationJSON;
@property (readonly, nonatomic) NSDictionary *conversationUpdateJSON;

@end

@interface ApptentiveLegacyConversation : NSObject <NSCoding>

@property (readonly, nonatomic) NSString *token;
@property (readonly, nonatomic) NSString *personID;
@property (readonly, nonatomic) NSString *deviceID;

@end

@protocol ApptentiveSessionDelegate <NSObject>

- (void)session:(ApptentiveSession *)session conversationDidChange:(NSDictionary *)payload;
- (void)session:(ApptentiveSession *)session deviceDidChange:(NSDictionary *)diffs;
- (void)session:(ApptentiveSession *)session personDidChange:(NSDictionary *)diffs;

@end
