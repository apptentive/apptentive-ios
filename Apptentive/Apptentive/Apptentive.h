//
//  Apptentive.h
//  Apptentive
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

//! Project version number for Apptentive.
/** The Apptentive version number */
FOUNDATION_EXPORT double ApptentiveVersionNumber;

//! Project version string for Apptentive.
/** The Apptentive version string */
FOUNDATION_EXPORT const unsigned char ApptentiveVersionString[];

/** The version number of the Apptentive SDK. */
#define kApptentiveVersionString @"4.0.7"

/** The platform that the SDK is built for. */
#define kApptentivePlatformString @"iOS"

/**
 A code corresponding to the reason that the Apptentive server authentication failed.
 */
typedef NS_ENUM(NSInteger, ApptentiveAuthenticationFailureReason) {
	/** An unknown authentication failure. */
	ApptentiveAuthenticationFailureReasonUnknown,
	/** An invalid JWT algorithm was used. */
	ApptentiveAuthenticationFailureReasonInvalidAlgorithm,
	/** A malformed JWT was encountered. */
	ApptentiveAuthenticationFailureReasonMalformedToken,
	/** An invalid JWT was encountered. */
	ApptentiveAuthenticationFailureReasonInvalidToken,
	/** A required subclaim was missing. */
	ApptentiveAuthenticationFailureReasonMissingSubClaim,
	/** A subclaim didn't match the logged-in session. */
	ApptentiveAuthenticationFailureReasonMismatchedSubClaim,
	/** An invalid subclaim was encountered. */
	ApptentiveAuthenticationFailureReasonInvalidSubClaim,
	/** The JWT expired. */
	ApptentiveAuthenticationFailureReasonExpiredToken,
	/** The JWT was revoked. */
	ApptentiveAuthenticationFailureReasonRevokedToken,
	/** The Apptentive App Key was missing. */
	ApptentiveAuthenticationFailureReasonMissingAppKey,
	/** The Apptentive App Signature was missing */
	ApptentiveAuthenticationFailureReasonMissingAppSignature,
	/** In invalid combination of an Apptentive App Key and an Apptentive App Signature was found. */
	ApptentiveAuthenticationFailureReasonInvalidKeySignaturePair
};

/** A block used to notify your app that an authenticated request failed to authenticate. */
typedef void (^ApptentiveAuthenticationFailureCallback)(ApptentiveAuthenticationFailureReason reason, NSString *errorMessage);

@protocol ApptentiveDelegate
, ApptentiveStyle;

/** Notification sent when Message Center unread messages count changes. */
extern NSNotificationName const ApptentiveMessageCenterUnreadCountChangedNotification;

/** Notification sent when the user has agreed to rate the application. */
extern NSNotificationName const ApptentiveAppRatingFlowUserAgreedToRateAppNotification;

/** Notification sent when a survey is shown. */
extern NSNotificationName const ApptentiveSurveyShownNotification;

/** Notification sent when a survey is submitted by the user. */
extern NSNotificationName const ApptentiveSurveySentNotification;

/** Error domain for the Apptentive SDK */
extern NSString *const ApptentiveErrorDomain;

/**
 When a survey is shown or sent, notification's userInfo dictionary will contain the ApptentiveSurveyIDKey key.
 Value is the ID of the survey that was shown or sent.
 */
extern NSString *const ApptentiveSurveyIDKey;

/** Supported Push Providers for use in `setPushNotificationIntegration:withDeviceToken:` */
typedef NS_ENUM(NSInteger, ApptentivePushProvider) {
	/** Specifies the Apptentive push provider. */
	ApptentivePushProviderApptentive,
	/** Specifies the Urban Airship push provider. */
	ApptentivePushProviderUrbanAirship,
	/** Specifies the Amazon Simple Notification Service push provider. */
	ApptentivePushProviderAmazonSNS,
	/** Specifies the Parse push provider. */
	ApptentivePushProviderParse,
};

/**
 Log levels supported by the logging system. Each level includes those above it on the list.
*/
typedef NS_ENUM(NSUInteger, ApptentiveLogLevel) {
	/** Critical failure log messages. */
	ApptentiveLogLevelCrit = 0,
	/** Error log messages. */
	ApptentiveLogLevelError = 1,
	/** Warning log messages. */
	ApptentiveLogLevelWarn = 2,
	/** Informational log messages. */
	ApptentiveLogLevelInfo = 3,
	/** Log messages that are potentially useful for debugging. */
	ApptentiveLogLevelDebug = 4,
	/** All possible log messages enabled. */
	ApptentiveLogLevelVerbose = 5
};

/**
 An `ApptentiveConfiguration` instance is used to pass configuration
 parameters into the `-registerWithConfiguration:` method.
 
 The `Apptentive` singleton instance makes a copy of the configuration
 parameters, so changes made to the configuration later
 will have no effect.
 */
@interface ApptentiveConfiguration : NSObject

/** The Apptentive App Key, obtained from your Apptentive dashboard. */
@property (copy, nonatomic, readonly) NSString *apptentiveKey;

/** The Apptentive App Signature, obtained from your Apptentive dashboard. */
@property (copy, nonatomic, readonly) NSString *apptentiveSignature;

/** The granularity of log messages emitted from the SDK (defaults to `ApptentiveLogLevelInfo`). */
@property (assign, nonatomic) ApptentiveLogLevel logLevel;

/** The server URL to use for API calls. Should only be used for testing. */
@property (copy, nonatomic) NSURL *baseURL;

/** The name of the distribution that includes the Apptentive SDK. For example "Cordova". */
@property (copy, nonatomic, nullable) NSString *distributionName;

/** The version of the distribution that includes the Apptentive SDK. */
@property (copy, nonatomic, nullable) NSString *distributionVersion;

/** The iTunes store app ID of the app (used for Apptentive rating prompt). */
@property (copy, nonatomic, nullable) NSString *appID;

/**
 Returns an instance of the `ApptentiveConfiguration` class
 initialized with the specified parameters.

 @param apptentiveKey The Apptentive App Key, obtained from your Apptentive dashboard.
 @param apptentiveSignature The Apptentive App Signature, obtained from your Apptentive dashboard.
 @return The newly-initiazlied configuration object.
 */
+ (nullable instancetype)configurationWithApptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature;

@end

/**
 `Apptentive` is a singleton which is used as the main point of entry for the Apptentive service.

## Configuration

 Before calling any other methods on the shared `Apptentive` instance, register you app key and signature:

    ApptentiveConfiguration *configuration = [ApptentiveConfiguration configurationWithApptentiveKey:@"your APP key here" apptentiveSignature:@"your APP signature here"];
    [Apptentive registerWithConfiguration:configuration];


## Engaging Events

 The Ratings Prompt and other Apptentive interactions are targeted to certain Apptentive events. For example,
 you could decide to show the Ratings Prompt after an event named "user_completed_level" has been engaged.
 You can later reconfigure the Ratings Prompt interaction to instead show after engaging "user_logged_in".

 You would add calls at these points to optionally engage with the user:

    [[Apptentive sharedConnection] engage:@"completed_level" fromViewController:viewController];

 See the readme for more information.

## Notifications

 `ApptentiveMessageCenterUnreadCountChangedNotification`

 Sent when the number of unread messages changes.
 The notification object is undefined. The `userInfo` dictionary contains a `count` key, the value of which
 is the number of unread messages.

 `ApptentiveAppRatingFlowUserAgreedToRateAppNotification`

 Sent when the user has agreed to rate the application.

 `ApptentiveSurveySentNotification`

 Sent when a survey is submitted by the user. The userInfo dictionary will have a key named `ApptentiveSurveyIDKey`,
 with a value of the id of the survey that was sent.

 */
@interface Apptentive : NSObject

///---------------------------------
/// @name Basic Usage
///---------------------------------
/** The shared singleton of `Apptentive`. */
+ (instancetype)sharedConnection;

/** Alias for `sharedConnection` */
@property (class, readonly, nonatomic) Apptentive *shared;

/** Initializes Apptentive instance with a given configuration */
+ (void)registerWithConfiguration:(ApptentiveConfiguration *)configuration;

/** The key copied from the configuration object. */
@property (readonly, nonatomic) NSString *apptentiveKey;

/** The signature copied from the configuration object. */
@property (readonly, nonatomic) NSString *apptentiveSignature;

/**
 The app's iTunes App ID.

 You can find this in iTunes Connect, and is the numeric "Apple ID" shown on your app details page.
 */
@property (copy, nonatomic, nullable) NSString *appID;

/** An object conforming to the `ApptentiveDelegate` protocol.
 If a `nil` value is passed for the view controller into methods such as	`-engage:fromViewController`,
 the SDK will request a view controller from the delegate from which to present an interaction.

 Deprecation Note: when a suitable view controller is not available for presenting interactions,
 the system will now use a new window to present Apptentive UI. */
@property (weak, nonatomic) id<ApptentiveDelegate> delegate DEPRECATED_ATTRIBUTE;

///--------------------
/// @name Engage Events
///--------------------

/**
 Shows interaction UI, if applicable, related to a given event.

 For example, if you have an upgrade message to display on app launch, you might call with event label set to
 `@"app.launch"` here, along with the view controller an upgrade message might be displayed from.

 @param event A string representing the name of the event.
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *_Nullable)viewController NS_SWIFT_NAME(engage(event:from:));

/**
 Shows interaction UI, if applicable, related to a given event, and attaches the specified custom data to the event.

 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData fromViewController:(UIViewController *_Nullable)viewController NS_SWIFT_NAME(engage(event:withCustomData:from:));

/**
 Shows interaction UI, if applicable, related to a given event. Attaches the specified custom data to the event along with the specified extended data.

 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param extendedData An array of dictionaries with specific Apptentive formatting. For example, [Apptentive extendedDataDate:[NSDate date]].
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData withExtendedData:(nullable NSArray<NSDictionary *> *)extendedData fromViewController:(UIViewController *_Nullable)viewController NS_SWIFT_NAME(engage(event:withCustomData:withExtendedData:from:));

/**
 Returns a Boolean value indicating whether the given event will cause an Interaction to be shown.

 For example, returns YES if a survey is ready to be shown the next time you engage your survey-targeted event. You can use this method to hide a "Show Survey" button in your app if there is no survey to take.

 @param event A string representing the name of the event.

 @return `YES` if the event will show an interaction, `NO` otherwise.
 */
- (BOOL)canShowInteractionForEvent:(NSString *)event;

///--------------------
/// @name Extended Data for Events
///--------------------

/**
 Used to specify a point in time in an event's extended data.

 @param date A date and time to be included in an event's extended data.

 @return An extended data dictionary representing a point in time, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataDate:(NSDate *)date NS_SWIFT_NAME(extendedData(date:));

/**
 Used to specify a geographic coordinate in an event's extended data.

 @param latitude A location's latitude coordinate.
 @param longitude A location's longitude coordinate.

 @return An extended data dictionary representing a geographic coordinate, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude NS_SWIFT_NAME(extendedData(latitude:longitude:));

/**
 Used to specify a commercial transaction (incorporating multiple items) in an event's extended data.

 @param transactionID The transaction's ID.
 @param affiliation The store or affiliation from which this transaction occurred.
 @param revenue The transaction's revenue.
 @param shipping The transaction's shipping cost.
 @param tax Tax on the transaction.
 @param currency Currency for revenue/shipping/tax values.
 @param commerceItems An array of commerce items contained in the transaction. Create commerce items with [Apptentive extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:].

 @return An extended data dictionary representing a commerce transaction, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataCommerceWithTransactionID:(nullable NSString *)transactionID
											affiliation:(nullable NSString *)affiliation
												revenue:(nullable NSNumber *)revenue
											   shipping:(nullable NSNumber *)shipping
													tax:(nullable NSNumber *)tax
											   currency:(nullable NSString *)currency
										  commerceItems:(nullable NSArray<NSDictionary *> *)commerceItems
	NS_SWIFT_NAME(extendedData(transactionID:affiliation:revenue:shipping:tax:currency:commerceItems:));

/**
 Used to specify a commercial transaction (consisting of a single item) in an event's extended data.

 @param itemID The transaction item's ID.
 @param name The transaction item's name.
 @param category The transaction item's category.
 @param price The individual item price.
 @param quantity The number of units purchased.
 @param currency Currency for price.

 @return An extended data dictionary representing a single item in a commerce transaction, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataCommerceItemWithItemID:(nullable NSString *)itemID
												name:(nullable NSString *)name
											category:(nullable NSString *)category
											   price:(nullable NSNumber *)price
											quantity:(nullable NSNumber *)quantity
											currency:(nullable NSString *)currency
	NS_SWIFT_NAME(extendedData(itemID:name:category:price:quantity:currency:));

///--------------------
/// @name Presenting UI
///--------------------

/**
 Determines if Message Center will be displayed when `presentMessageCenterFromViewController:` is called.

 If app has not yet synced with Apptentive, you will be unable to display Message Center. Use `canShowMessageCenter`
 to determine if Message Center is ready to be displayed. If Message Center is not ready you could, for example,
 hide the "Message Center" button in your interface.
 **/

@property (readonly, nonatomic) BOOL canShowMessageCenter;

/**
 Presents Message Center modally from the specified view controller.

 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.

 @param viewController The view controller from which to present Message Center.

 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController;

/**
 Presents Message Center from a given view controller with custom data.

 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.

 @param viewController The view controller from which to present Message Center.
 @param customData A dictionary of key/value pairs to be associated with any messages sent via Message Center.

 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData;

/**
 Dismisses Message Center.

 @param animated `YES` to animate the dismissal, otherwise `NO`.
 @param completion A block called at the conclusion of the message center being dismissed.

 @note Under normal circumstances, Message Center will be dismissed by the user tapping the Close button, so it is not necessary to call this method.
 */
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(nullable void (^)(void))completion;

///-------------------------------------
/// @name Displaying Unread Message Count
///-------------------------------------

/**
 Returns the current number of unread messages in Message Center.

 These are the messages sent via the Apptentive website to this user.

 @return The number of unread messages.
 */
@property (readonly, nonatomic) NSUInteger unreadMessageCount;

/**
 Returns a "badge" than can be used as a UITableViewCell accessoryView to indicate the current number of unread messages.

 To keep this value updated, your view controller will must register for `ApptentiveMessageCenterUnreadCountChangedNotification`
 and reload the table view cell when a notification is received.

 @param apptentiveHeart A Boolean value indicating whether to include a heart logo adjacent to the number.

 @return A badge view suitable for use as a table view cell accessory view.
 */
- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart NS_SWIFT_NAME(unreadMessageCountAccessoryView(apptentiveHeart:));

///---------------------------------------
/// @name Open App Store
///---------------------------------------

/**
 Open your app's page on the App Store or Mac App Store.

 This method can be used to power, for example, a "Rate this app" button in your settings screen.
 `openAppStore` opens the app store directly, without the normal Apptentive Ratings Prompt.
 */
- (void)openAppStore;

///------------------------------------
/// @name Enable Push Notifications
///------------------------------------

/**
 Register for Push Notifications with the given service provider.

 Uses the `deviceToken` from `application:didRegisterForRemoteNotificationsWithDeviceToken:`

 Only one Push Notification Integration can be added at a time. Setting a Push Notification
 Integration removes all previously set Push Notification Integrations.

 To enable background fetching of Message Center messages upon receiving a remote notification,
 add `remote-notification` as a `UIBackgroundModes` value in your app's Info.plist.

 @param pushProvider The Push Notification provider with which to register.
 @param deviceToken The device token used to send Remote Notifications.
 **/

- (void)setPushNotificationIntegration:(ApptentivePushProvider)pushProvider withDeviceToken:(NSData *)deviceToken NS_SWIFT_NAME(setPushProvider(_:deviceToken:));

/**
 Forwards a push notification from your application delegate to Apptentive Connect.

 If the push notification originated from Apptentive, Message Center will be presented from the view controller
 when the notification is tapped.

 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.

 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.
 */
- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;

/**
 Forwards a push notification from your application delegate to Apptentive.

 If the push notification originated from Apptentive, Message Center will be presented from the view controller
 when the notification is tapped.

 Apptentive will attempt to fetch Messages Center messages in the background when the notification is received.

 To enable background fetching of Message Center messages upon receiving a remote notification,
 add `remote-notification` as a `UIBackgroundModes` value in your app's Info.plist.

 The `completionHandler` block will be called when the message fetch is completed. To ensure that messages can be
 retrieved, please do not call the `completionHandler` block yourself if the notification was sent by Apptentive.

 If the notification was not sent by Apptentive, the parent app is responsible for calling the `completionHandler` block.

 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.
 @param completionHandler The block to execute when the message fetch operation is complete.

 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.
 */
- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

/**
 Forwards a local notification from your application delegate to Apptentive.

 @param notification The `UILocalNotification` object received by the application delegate.
 @param viewController The view controller Message Center may be presented from.
 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (BOOL)didReceiveLocalNotification:(UILocalNotification *)notification fromViewController:(UIViewController *)viewController NS_SWIFT_NAME(didReceiveLocalNotification(_:from:));
#pragma clang diagnostic pop

/**
 Forwards a user notification from your user notification center delegate to Apptentive.
 In the event that this method returns `NO`, your code must call the completion handler. 

 @param response The notification response
 @param completionHandler The completion handler that will be called if the notification was sent by Apptentive
 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.

 */

- (BOOL)didReceveUserNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler;

///-------------------------------------
/// @name Attach Text, Images, and Files
///-------------------------------------

/**
 Attaches text to the user's feedback. This method should be called from the main thread only.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param text The text to attach to the user's feedback as a file.
 */
- (void)sendAttachmentText:(NSString *)text NS_SWIFT_NAME(sendAttachment(_:));

/**
 Attaches an image the user's feedback. This method should be called from the main thread only.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param image The image to attach to the user's feedback as a file.
 */
- (void)sendAttachmentImage:(UIImage *)image NS_SWIFT_NAME(sendAttachment(_:));

/**
 Attaches an arbitrary file to the user's feedback. This method should be called from the main thread only.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param fileData The contents of the file as data.
 @param mimeType The MIME type of the file data.
 */
- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType NS_SWIFT_NAME(sendAttachment(_:mimeType:));

///---------------------------------------
/// @name Add Custom Device or Person Data
///---------------------------------------

/** The name of the app user when communicating with Apptentive. */
@property (copy, nonatomic, nullable) NSString *personName;
/** The email address of the app user in form fields and communicating with Apptentive. */
@property (copy, nonatomic, nullable) NSString *personEmailAddress;

/**
 Removes custom data associated with the current person.

 Will remove data, if any, associated with the current person with the key `key`.

 @param key The key of the data.
 */
- (void)removeCustomPersonDataWithKey:(NSString *)key;

/**
 Removes custom data associated with the current device.

 Will remove data, if any, associated with the current device with the key `key`.

 @param key The key of the data.
 */
- (void)removeCustomDeviceDataWithKey:(NSString *)key;

/**
 Adds custom text data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param string Custom data of type `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key NS_SWIFT_NAME(addCustomDeviceData(_:withKey:));

/**
 Adds custom numeric data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param number Custom data of type `NSNumber`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key NS_SWIFT_NAME(addCustomDeviceData(_:withKey:));

/**
 Adds custom Boolean data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param boolValue Custom data of type `BOOL`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key NS_SWIFT_NAME(addCustomDeviceData(_:withKey:));

/**
 Adds custom text data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param string Custom data of type `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key NS_SWIFT_NAME(addCustomPersonData(_:withKey:));

/**
 Adds custom numeric data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param number Custom data of type `NSNumber`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key NS_SWIFT_NAME(addCustomPersonData(_:withKey:));


/**
 Adds custom Boolean data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param boolValue Custom data of type `BOOL`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key NS_SWIFT_NAME(addCustomPersonData(_:withKey:));

///------------------------------------
/// @name Miscellaneous
///------------------------------------


/**
 Dismisses any currently-visible interactions.

 @note This method is for internal use and is subject to change.

 @param animated Whether to animate the dismissal.
 */
- (void)dismissAllInteractions:(BOOL)animated NS_SWIFT_NAME(dismissAllInteractions(animated:));

///---------------------------------
/// @name Interface Customization
///---------------------------------

/** The style sheet used for styling Apptentive UI.

 @note See the [Apptentive Styling Guide for iOS](https://docs.apptentive.com/ios/customization/) for information on configuring this property.
 */
@property (strong, nonatomic) id<ApptentiveStyle> styleSheet;


#if APPTENTIVE_DEBUG
- (void)checkSDKConfiguration;
#endif

///---------------------------------
/// @name Authentication
///---------------------------------

/**
 Logs the specified user in, using the value of the proof parameter to
 ensure that the login attempt is authorized.

 @param token An authorization token.
 @param completion A block that is called when the login attempt succeeds or fails.
 */
- (void)logInWithToken:(NSString *)token completion:(void (^)(BOOL success, NSError *error))completion;

/**
 Ends the current user session. The user session will be persisted in a logged-out state
 so that it can be resumed using the logIn: method.
 */
- (void)logOut;

/**
 A block that is called when a logged-in conversation's request fails due to a problem with the user's JWT.
 */
@property (copy, nonatomic) ApptentiveAuthenticationFailureCallback authenticationFailureCallback;

///---------------------------------
/// @name Logging System
///---------------------------------

@property (assign, nonatomic) ApptentiveLogLevel logLevel;

@end

@protocol ApptentiveDelegate <NSObject>
@optional

/**
 Returns a view controller from which to present the an interaction.

 @param connection The `Apptentive` object that is requesting a view controller to present from.

 @return The view controller your app would like the interaction to be presented from.

 Deprecation Note: when a suitable view controller is not available for presenting interactions,
 the system will now use a new window to present Apptentive UI. */
- (UIViewController *)viewControllerForInteractionsWithConnection:(Apptentive *)connection NS_SWIFT_NAME(viewControllerForInteractions(with:)) DEPRECATED_ATTRIBUTE;

@end

/**
 The `ApptentiveNavigationController class is an empty subclass of UINavigationController that
 can be used to target UIAppearance settings specifically to Apptentive UI.

 For instance, to override the default `barTintColor` (white) for navigation controllers
 in the Apptentive UI, you would call:

	[[UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor = [UIColor magentaColor];

 */
@interface ApptentiveNavigationController : UINavigationController
@end

/**
 The ApptentiveStyle protocol allows extensive customization of the fonts and colors used by the Apptentive SDK's UI.

 A class implementing this protocol must handle resizing text according to the applications content size to support dynamic type.
 */
@protocol ApptentiveStyle <NSObject>

/** A typealias for string used to identify a text style or color. */
typedef NSString *ApptentiveStyleIdentifier NS_EXTENSIBLE_STRING_ENUM;

/**
 @param textStyle the text style whose font should be returned.
 @return the font to use for the given style.
 */
- (UIFont *)fontForStyle:(ApptentiveStyleIdentifier)textStyle NS_SWIFT_NAME(font(for:));

/**
 @param style the style whose color should be returned.
 @return the color to use for the given style.
 */
- (UIColor *)colorForStyle:(ApptentiveStyleIdentifier)style NS_SWIFT_NAME(color(for:));

@end

NS_ASSUME_NONNULL_END

#import "ApptentiveStyleSheet.h"

NS_ASSUME_NONNULL_BEGIN

/// The text style for the title text of the greeting view in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleBody NS_SWIFT_NAME(body);

/// The text style for the title text of the greeting view in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleHeaderTitle NS_SWIFT_NAME(headerTitle);

/// The text style for the message text of the greeting view in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleHeaderMessage NS_SWIFT_NAME(headerMessage);

/// The text style for the date lables in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleMessageDate NS_SWIFT_NAME(messageDate);

/// The text style for the message sender text in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleMessageSender NS_SWIFT_NAME(messageSender);

/// The text style for the message status text in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleMessageStatus NS_SWIFT_NAME(messageStatus);

/// The text style for the message center status text in Message Center.
extern ApptentiveStyleIdentifier ApptentiveTextStyleMessageCenterStatus NS_SWIFT_NAME(messageCenterStatus);

/// The text style for the survey description text.
extern ApptentiveStyleIdentifier ApptentiveTextStyleSurveyInstructions NS_SWIFT_NAME(surveyInstructions);

/// The text style for buttons that make changes when tapped.
extern ApptentiveStyleIdentifier ApptentiveTextStyleDoneButton NS_SWIFT_NAME(doneButton);

/// The text style for buttons that cancel or otherwise don't make changes when tapped.
extern ApptentiveStyleIdentifier ApptentiveTextStyleButton NS_SWIFT_NAME(button);

/// The text style for the the submit button on Surveys.
extern ApptentiveStyleIdentifier ApptentiveTextStyleSubmitButton NS_SWIFT_NAME(submitButton);

/// The text style for text input fields.
extern ApptentiveStyleIdentifier ApptentiveTextStyleTextInput NS_SWIFT_NAME(textInput);


/// The background color for headers in Message Center and Surveys.
extern ApptentiveStyleIdentifier ApptentiveColorHeaderBackground NS_SWIFT_NAME(headerBackground);

/// The background color for the footer in Surveys.
extern ApptentiveStyleIdentifier ApptentiveColorFooterBackground NS_SWIFT_NAME(footerBackground);

/// The foreground color for text and borders indicating a failure of validation or sending.
extern ApptentiveStyleIdentifier ApptentiveColorFailure NS_SWIFT_NAME(failure);

/// The foreground color for borders in Message Center and Surveys.
extern ApptentiveStyleIdentifier ApptentiveColorSeparator NS_SWIFT_NAME(separator);

/// The background color for cells in Message Center and Surveys.
extern ApptentiveStyleIdentifier ApptentiveColorBackground NS_SWIFT_NAME(background);

/// The background color for table- and collection views.
extern ApptentiveStyleIdentifier ApptentiveColorCollectionBackground NS_SWIFT_NAME(collectionBackground);

/// The background color for text input fields.
extern ApptentiveStyleIdentifier ApptentiveColorTextInputBackground NS_SWIFT_NAME(textInputBackground);

/// The color for text input placeholder text.
extern ApptentiveStyleIdentifier ApptentiveColorTextInputPlaceholder NS_SWIFT_NAME(textInputPlaceholder);

/// The background color for message cells in Message Center.
extern ApptentiveStyleIdentifier ApptentiveColorMessageBackground NS_SWIFT_NAME(messageBackground);

/// The background color for reply cells in Message Center.
extern ApptentiveStyleIdentifier ApptentiveColorReplyBackground NS_SWIFT_NAME(replyBackground);

/// The background color for context cells in Message Center.
extern ApptentiveStyleIdentifier ApptentiveColorContextBackground NS_SWIFT_NAME(contextBackground);

NS_ASSUME_NONNULL_END
