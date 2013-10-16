//
//  ATEngagementBackend.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATEngagementInstallDateKey;
NSString *const ATEngagementUpgradeDateKey;
NSString *const ATEngagementCodePointsInvokesTotalKey;
NSString *const ATEngagementCodePointsInvokesVersionKey;
NSString *const ATEngagementInteractionsInvokesTotalKey;
NSString *const ATEngagementInteractionsInvokesVersionKey;

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

- (void)engage:(NSString *)codePoint;
- (void)codePointWasEngaged:(NSString *)codePoint;
- (void)interactionWasEngaged:(ATInteraction *)interaction;

- (void)presentInteraction:(ATInteraction *)interaction;
- (void)presentUpgradeMessageInteraction:(ATInteraction *)interaction;
- (void)presentEnjoymentDialogInteraction:(ATInteraction *)interaction;

@end
