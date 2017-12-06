//
//  Apptentive_Private.h
//  Apptentive
//
//  Created by Andrew Wooster on 1/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#if NO_USE_FRAMEWORKS
#import "Apptentive.h"
#else
#import <Apptentive/Apptentive.h>
#endif

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName _Nonnull const ApptentiveCustomPersonDataChangedNotification;
extern NSNotificationName _Nonnull const ApptentiveCustomDeviceDataChangedNotification;
extern NSNotificationName _Nonnull const ApptentiveInteractionsDidUpdateNotification;
extern NSNotificationName _Nonnull const ApptentiveInteractionsShouldDismissNotification;
extern NSNotificationName _Nonnull const ApptentiveManifestRawDataDidReceiveNotification;

extern NSString *_Nonnull const ApptentiveInteractionsShouldDismissAnimatedKey;
extern NSNotificationName _Nonnull const ApptentiveConversationCreatedNotification;
extern NSString *_Nonnull const ApptentiveCustomDeviceDataPreferenceKey;
extern NSString *_Nonnull const ApptentiveCustomPersonDataPreferenceKey;
extern NSString *_Nonnull const ApptentiveManifestRawDataKey;

@class ApptentiveMessage, ApptentiveBackend, ApptentiveDispatchQueue;

@interface Apptentive ()

/*!
 * This private serial queue is used for all Apptentive internal API calls and callbacks.
 * You may think of it as of the 'main' queue for the SDK itself.
 */
@property (readonly, nonatomic) ApptentiveDispatchQueue *operationQueue;

@property (readonly, nonatomic) NSURL *baseURL;
@property (readonly, nonatomic) ApptentiveBackend *backend;

//@property (copy, nonatomic, nullable) NSDictionary *pushUserInfo;
//@property (strong, nonatomic, nullable) UIViewController *pushViewController;

@property (readonly, nonatomic) id<ApptentiveStyle> style;
@property (readonly, nonatomic) BOOL didAccessStyleSheet;

+ (NSDictionary *)timestampObjectWithNumber:(NSNumber *)seconds;
+ (NSDictionary *)versionObjectWithVersion:(NSString *)version;
+ (NSDictionary *)timestampObjectWithDate:(NSDate *)date;

- (UIViewController *)viewControllerForInteractions;

- (void)dispatchOnOperationQueue:(void (^)(void))block;

@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls
 localized strings out of the resource bundle. */
extern NSString *ApptentiveLocalizedString(NSString *key, NSString *_Nullable comment);

extern ApptentiveAuthenticationFailureReason parseAuthenticationFailureReason(NSString *reason);


@interface ApptentiveNavigationController (AboutView)

- (void)pushAboutApptentiveViewController;

@end


@interface ApptentiveNavigationController (UIWindow)

- (void)presentAnimated:(BOOL)animated completion:(void (^__nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
