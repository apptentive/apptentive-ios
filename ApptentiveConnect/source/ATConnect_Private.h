//
//  ATConnect_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConnect.h"

extern NSString *const ATConnectCustomPersonDataChangedNotification;
extern NSString *const ATConnectCustomDeviceDataChangedNotification;

@class ATMessage;


@interface ATConnect ()

- (NSDictionary *)customPersonData;
- (NSDictionary *)customDeviceData;
- (NSDictionary *)integrationConfiguration;

@property (strong, nonatomic) NSDictionary *pushUserInfo;
@property (strong, nonatomic) UIViewController *pushViewController;

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

// Debug/test interactions by invoking them directly
- (NSArray *)engagementInteractions;
- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index;
- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index;
- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController;

- (void)showNotificationBannerForMessage:(ATMessage *)message;

+ (NSDictionary *)timestampObjectWithNumber:(NSNumber *)seconds;
+ (NSDictionary *)versionObjectWithVersion:(NSString *)version;
+ (NSDictionary *)timestampObjectWithDate:(NSDate *)date;

@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls
 localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString *comment);
