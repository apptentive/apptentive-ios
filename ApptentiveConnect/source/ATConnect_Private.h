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

@interface ATConnect ()

- (NSDictionary *)customPersonData;
- (NSDictionary *)customDeviceData;
- (NSDictionary *)integrationConfiguration;
- (BOOL)messageCenterEnabled;
- (BOOL)emailRequired;

#if TARGET_OS_IPHONE
- (void)presentFeedbackDialogFromViewController:(UIViewController *)viewController;

// For debugging only.
- (void)resetUpgradeData;
#endif

/*!
 * Returns the NSBundle corresponding to the bundle containing ATConnect's
 * images, xibs, strings files, etc.
 */
+ (NSBundle *)resourceBundle;

// Debug/test interactions by invoking them directly
- (NSArray *)engagementInteractions;
- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index;
- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index;
- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController;

@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls
 localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString *comment);
