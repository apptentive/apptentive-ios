//
//  Apptentive+Debugging.h
//  Apptentive
//
//  Created by Andrew Wooster on 4/23/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Apptentive_Private.h"

typedef NS_OPTIONS(NSInteger, ApptentiveDebuggingOptions) {
	ApptentiveDebuggingOptionsNone = 0,
	ApptentiveDebuggingOptionsShowDebugPanel = 1 << 0,
	ApptentiveDebuggingOptionsLogHTTPFailures = 1 << 1,
	ApptentiveDebuggingOptionsLogAllHTTPRequests = 1 << 2,
};

NS_ASSUME_NONNULL_BEGIN


@interface Apptentive ()

@property (assign, nonatomic) ApptentiveDebuggingOptions debuggingOptions;

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL;

@end


@interface Apptentive (Debugging)

@property (readonly, nonatomic) NSURL *_Nullable baseURL;
@property (readonly, nonatomic) NSString *storagePath;
@property (readonly, nonatomic) NSString *SDKVersion;
@property (readonly, nonatomic) UIView *_Nullable unreadAccessoryView;
@property (readonly, nonatomic) NSString *_Nullable manifestJSON;
@property (readonly, nonatomic) NSDictionary<NSString *, NSObject *> *deviceInfo;
@property (readonly, nonatomic, nullable) NSString *conversationToken;
@property (strong, nonatomic, nullable) NSURL *localInteractionsURL;

@property (readonly, nonatomic) NSDictionary *customPersonData;
@property (readonly, nonatomic) NSDictionary *customDeviceData;

- (NSArray<NSString *> *)engagementEvents;
- (NSArray *)engagementInteractions;
- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index;
- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index;
- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController;
- (void)presentInteractionWithJSON:(NSDictionary *)JSON fromViewController:(UIViewController *)viewController;

#pragma mark - Conversation Metadata

@property (readonly, nonatomic) NSInteger numberOfConversations;

- (NSString *)conversationStateAtIndex:(NSInteger)index;
- (NSString *)conversationDescriptionAtIndex:(NSInteger)index;
- (BOOL)conversationIsActiveAtIndex:(NSInteger)index;
- (void)deleteConversationAtIndex:(NSInteger)index;

- (void)resetSDK;

@end

NS_ASSUME_NONNULL_END
