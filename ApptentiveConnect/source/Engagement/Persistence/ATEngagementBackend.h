//
//  ATEngagementBackend.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NSString *const ATEngagementInstallDateKey;
NSString *const ATEngagementUpgradeDateKey;
NSString *const ATEngagementLastUsedVersionKey;
NSString *const ATEngagementIsUpdateVersionKey;
NSString *const ATEngagementIsUpdateBuildKey;
NSString *const ATEngagementCodePointsInvokesTotalKey;
NSString *const ATEngagementCodePointsInvokesVersionKey;
NSString *const ATEngagementCodePointsInvokesBuildKey;
NSString *const ATEngagementCodePointsInvokesLastDateKey;
NSString *const ATEngagementInteractionsInvokesTotalKey;
NSString *const ATEngagementInteractionsInvokesVersionKey;
NSString *const ATEngagementInteractionsInvokesBuildKey;
NSString *const ATEngagementInteractionsInvokesLastDateKey;

@class ATInteraction;

@interface ATEngagementBackend : NSObject {
@private
	NSMutableDictionary *codePointInteractions;
}

+ (ATEngagementBackend *)sharedBackend;

- (void)checkForEngagementManifest;
- (BOOL)shouldRetrieveNewEngagementManifest;
- (void)didReceiveNewCodePointInteractions:(NSDictionary *)codePointInteractions maxAge:(NSTimeInterval)expiresMaxAge;
- (void)updateVersionInfo;
+ (NSString *)cachedEngagementStoragePath;

- (NSArray *)interactionsForCodePoint:(NSString *)codePoint;
- (ATInteraction *)interactionForCodePoint:(NSString *)codePoint;

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string;
- (BOOL)engageLocalEvent:(NSString *)eventLabel fromViewController:(UIViewController *)viewController;
- (BOOL)engageLocalEvent:(NSString *)eventLabel userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (BOOL)engageApptentiveAppEvent:(NSString *)eventLabel userInfo:(NSDictionary *)userInfo;
- (BOOL)engageApptentiveEvent:(NSString *)eventLabel fromInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;
- (BOOL)engageApptentiveEvent:(NSString *)eventLabel fromInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo;

- (BOOL)engageEvent:(NSString *)eventLabel fromVendor:(NSString *)vendor fromInteraction:(NSString *)interaction userInfo:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;
- (BOOL)engageEvent:(NSString *)eventLabel fromVendor:(NSString *)vendor fromInteraction:(NSString *)interaction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (BOOL)engage:(NSString *)codePoint userInfo:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;
- (BOOL)engage:(NSString *)codePoint userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (void)codePointWasSeen:(NSString *)codePoint;
- (void)codePointWasEngaged:(NSString *)codePoint;
- (void)interactionWasSeen:(NSString *)interactionID;
- (void)interactionWasEngaged:(ATInteraction *)interaction;

- (void)presentInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;
- (void)presentUpgradeMessageInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;
- (void)presentEnjoymentDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;

// Used for debugging only.
- (void)resetUpgradeVersionInfo;
@end
