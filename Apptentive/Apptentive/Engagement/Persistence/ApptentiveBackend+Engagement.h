//
//  ApptentiveEngagementBackend.h
//  Apptentive
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveBackend.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ATEngagementInstallDateKey;
extern NSString *const ATEngagementUpgradeDateKey;
extern NSString *const ATEngagementLastUsedVersionKey;
extern NSString *const ATEngagementIsUpdateVersionKey;
extern NSString *const ATEngagementIsUpdateBuildKey;
extern NSString *const ATEngagementCodePointsInvokesTotalKey;
extern NSString *const ATEngagementCodePointsInvokesVersionKey;
extern NSString *const ATEngagementCodePointsInvokesBuildKey;
extern NSString *const ATEngagementCodePointsInvokesLastDateKey;
extern NSString *const ATEngagementInteractionsInvokesTotalKey;
extern NSString *const ATEngagementInteractionsInvokesVersionKey;
extern NSString *const ATEngagementInteractionsInvokesBuildKey;
extern NSString *const ATEngagementInteractionsInvokesLastDateKey;
extern NSString *const ATEngagementInteractionsSDKVersionKey;

extern NSString *const ATEngagementCodePointHostAppVendorKey;
extern NSString *const ATEngagementCodePointHostAppInteractionKey;
extern NSString *const ATEngagementCodePointApptentiveVendorKey;
extern NSString *const ATEngagementCodePointApptentiveAppInteractionKey;

extern NSString *const ApptentiveEngagementMessageCenterEvent;

@class ApptentiveInteraction;


@interface ApptentiveBackend (Engagement)

- (ApptentiveInteraction *)interactionForIdentifier:(NSString *)identifier;
- (ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations;

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event;
- (BOOL)canShowInteractionForCodePoint:(NSString *)codePoint;

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string;
+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event;

- (void)engageApptentiveAppEvent:(NSString *)event;
- (void)engageLocalEvent:(NSString *)event userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController;
- (void)engageLocalEvent:(NSString *)event userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(BOOL engaged))completion;

- (void)engageCodePoint:(NSString *)codePoint fromInteraction:(nullable ApptentiveInteraction *)fromInteraction userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController;

- (void)engageCodePoint:(NSString *)codePoint fromInteraction:(nullable ApptentiveInteraction *)fromInteraction userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(BOOL engaged))completion;

- (void)codePointWasSeen:(NSString *)codePoint;

- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController;
- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo;
- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData;
- (void)engage:(NSString *)event fromInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController userInfo:(nullable NSDictionary *)userInfo customData:(nullable NSDictionary *)customData extendedData:(nullable NSArray *)extendedData completion:(void (^ _Nullable)(BOOL))completion;
- (void)interactionWasSeen:(NSString *)interactionID;

- (void)presentInteraction:(ApptentiveInteraction *)interaction fromViewController:(nullable UIViewController *)viewController;

- (void)invokeAction:(NSDictionary *)actionConfig withInteraction:(ApptentiveInteraction *)sourceInteraction fromViewController:(UIViewController *)fromViewController;

@end

NS_ASSUME_NONNULL_END
