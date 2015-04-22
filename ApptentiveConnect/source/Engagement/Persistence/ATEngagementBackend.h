//
//  ATEngagementBackend.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

extern NSString *const ATEngagementCodePointHostAppVendorKey;
extern NSString *const ATEngagementCodePointHostAppInteractionKey;
extern NSString *const ATEngagementCodePointApptentiveVendorKey;
extern NSString *const ATEngagementCodePointApptentiveAppInteractionKey;

@class ATInteraction;

@interface ATEngagementBackend : NSObject {
@private
	NSMutableDictionary *_engagementTargets;
	NSMutableDictionary *_engagementInteractions;
}

+ (ATEngagementBackend *)sharedBackend;

- (void)checkForEngagementManifest;
- (BOOL)shouldRetrieveNewEngagementManifest;

- (void)didReceiveNewTargets:(NSDictionary *)targets andInteractions:(NSDictionary *)interactions maxAge:(NSTimeInterval)expiresMaxAge;

- (void)updateVersionInfo;
+ (NSString *)cachedTargetsStoragePath;
+ (NSString *)cachedInteractionsStoragePath;

- (ATInteraction *)interactionForEvent:(NSString *)event;

- (ATInteraction *)interactionForInvocations:(NSArray *)invocations;

- (BOOL)willShowInteractionForLocalEvent:(NSString *)event;
- (BOOL)willShowInteractionForCodePoint:(NSString *)codePoint;

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string;
+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event;

- (BOOL)engageApptentiveAppEvent:(NSString *)event;
- (BOOL)engageLocalEvent:(NSString *)event userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (BOOL)engageCodePoint:(NSString *)codePoint fromInteraction:(ATInteraction *)fromInteraction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (void)codePointWasSeen:(NSString *)codePoint;
- (void)codePointWasEngaged:(NSString *)codePoint;
- (void)interactionWasSeen:(NSString *)interactionID;
- (void)interactionWasEngaged:(ATInteraction *)interaction;

- (void)presentInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;
- (void)presentUpgradeMessageInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;
- (void)presentEnjoymentDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;

- (void)presentNavigateToLinkInteraction:(ATInteraction *)interaction;

// Used for debugging only.
- (void)resetUpgradeVersionInfo;
- (NSArray *)allEngagementInteractions;

@end
