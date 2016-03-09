//
//  ATConnect_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConnect.h"

NS_ASSUME_NONNULL_BEGIN

@class ATCompoundMessage, ATWebClient, ATBackend, ATEngagementBackend;

@interface ATConnect ()

@property (readonly, nonatomic) NSMutableDictionary *integrationConfiguration;

@property (readonly, nonatomic) ATWebClient *webClient;
@property (readonly, nonatomic) ATBackend *backend;
@property (readonly, nonatomic) ATEngagementBackend *engagementBackend;

@property (strong, nonatomic) NSDictionary * __nullable pushUserInfo;
@property (strong, nonatomic) UIViewController * __nullable pushViewController;

#if TARGET_OS_IPHONE

// For debugging only.
- (void)resetUpgradeData;
#endif

/*!
 * Returns the NSBundle corresponding to the bundle containing ATConnect's
 * images, xibs, strings files, etc.
 */
+ (NSBundle *)resourceBundle;
+ (UIStoryboard *)storyboard;

- (void)showNotificationBannerForMessage:(ATCompoundMessage *)message;

+ (NSDictionary *)timestampObjectWithNumber:(NSNumber *)seconds;
+ (NSDictionary *)versionObjectWithVersion:(NSString *)version;
+ (NSDictionary *)timestampObjectWithDate:(NSDate *)date;

@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls
 localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString * __nullable comment);

NS_ASSUME_NONNULL_END
