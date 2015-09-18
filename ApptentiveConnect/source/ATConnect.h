//
//  ATConnect.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#define kATConnectVersionString @"2.0.2"

#if TARGET_OS_IPHONE
#	define kATConnectPlatformString @"iOS"
#elif TARGET_OS_MAC
#	define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

@protocol ATConnectDelegate;

/** Notification sent when Message Center unread messages count changes. */
extern NSString *const ATMessageCenterUnreadCountChangedNotification;

/** Notification sent when the user has agreed to rate the application. */
extern NSString *const ATAppRatingFlowUserAgreedToRateAppNotification;

/** Notification sent when a survey is shown. */
extern NSString *const ATSurveyShownNotification;

/** Notification sent when a survey is submitted by the user. */
extern NSString *const ATSurveySentNotification;

/**
 When a survey is shown or sent, notification's userInfo dictionary will contain the ATSurveyIDKey key.
 Value is the ID of the survey that was shown or sent.
 */
extern NSString *const ATSurveyIDKey;

/** Supported Push Providers for use in `setPushNotificationIntegration:withDeviceToken:` */
typedef NS_ENUM(NSInteger, ATPushProvider){
	ATPushProviderApptentive,
	ATPushProviderUrbanAirship,
	ATPushProviderAmazonSNS,
	ATPushProviderParse,
};

/**
 `ATConnect` is a singleton which is used as the main point of entry for the Apptentive service.
 
 ## Configuration
 
Before calling any other methods on the shared `ATConnect` instance, set the API key:
 
     [[ATConnect sharedConnection].apiKey = @"your API key here";
 
 ## Engagement Events
 
 The Ratings Prompt and other Apptentive interactions are targeted to certain Apptentive events. For example,
 you could decide to show the Ratings Prompt after an event named "user_completed_level" has been engaged.
 You can later reconfigure the Ratings Prompt interaction to instead show after engaging "user_logged_in".
 
 You would add calls at these points to optionally engage with the user:
 
     [[ATConnect sharedConnection] engage:@"completed_level" fromViewController:viewController];
 
 See the readme for more information.
 
 ## Notifications
 
 `ATMessageCenterUnreadCountChangedNotification`
 
 Sent when the number of unread messages changes.
 The notification object is undefined. The `userInfo` dictionary contains a `count` key, the value of which
 is the number of unread messages.
 
 `ATAppRatingFlowUserAgreedToRateAppNotification`
 
 Sent when the user has agreed to rate the application.
 
 `ATSurveySentNotification`
 
 Sent when a survey is submitted by the user. The userInfo dictionary will have a key named `ATSurveyIDKey`,
 with a value of the id of the survey that was sent.
 
 ## Integrations
 
 Keys for currently supported integrations:
 
 * `ATIntegrationKeyApptentive` - For Apptentive Push
 * `ATIntegrationKeyUrbanAirship` - For Urban Airship
 * `ATIntegrationKeyAmazonSNS` - For Amazon SNS
 * `ATIntegrationKeyKahuna` - For Kahuna
 * `ATIntegrationKeyParse` - For Parse
 */
@interface ATConnect : NSObject

///---------------------------------
/// @name Basic Usage
///---------------------------------
/**
 The API key for Apptentive.
 
 This key is found on the Apptentive website under Settings, API & Development.
 */
@property (nonatomic, copy) NSString *apiKey;

/**
 The app's iTunes App ID.
 
 You can find this in iTunes Connect, and is the numeric "Apple ID" shown on your app details page.
 */
@property (nonatomic, copy) NSString *appID;

/** The shared singleton of `ATConnect`. */
+ (ATConnect *)sharedConnection;

/** An object conforming to the `ATConnectDelegate` protocol */
@property (nonatomic, weak) id<ATConnectDelegate> delegate;

///---------------------------------
/// @name Interface Customization
///---------------------------------
/** Toggles the display of an email field in the message panel. `YES` by default. */
@property (nonatomic, assign) BOOL showEmailField;
/** Set this if you want some custom text to appear as a placeholder in the feedback text box. */
@property (nonatomic, copy) NSString *customPlaceholderText;
#if TARGET_OS_IPHONE
/**
 A tint color to use in Apptentive-specific UI.
 
 Overrides the default tintColor acquired from your app, in case you're using one that doesn't look great
 with Apptentive-specific UI. 
 
 @deprecated Use `[UIAppearance appearanceWhenContainedIn:[ATNavigationController class], nil].tintColor`
 */
@property (nonatomic, strong) UIColor *tintColor DEPRECATED_ATTRIBUTE;
#endif

#if TARGET_OS_IPHONE

///--------------------
/// @name Presenting UI
///--------------------

/**
 Determines if Message Center will be displayed when `presentMessageCenterFromViewController:` is called.
 
 If app has not yet synced with Apptentive, you will be unable to display Message Center. Use `canShowMessageCenter`
 to determine if Message Center is ready to be displayed. If Message Center is not ready you could, for example,
 hide the "Message Center" button in your interface.
 **/

- (BOOL)canShowMessageCenter;

/**
 Presents Message Center modally from the specified view controller.
 
 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.
 
 @param viewController The view controller from which to present Message Center.
 
 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;

/**
 Presents Message Center from a given view controller with custom data.
 
 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.
 
 @param viewController The view controller from which to present Message Center.
 @param customData A dictionary of key/value pairs to be associated with any messages sent via Message Center.
 
 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;

/**
 Returns the current number of unread messages in Message Center.
 
 These are the messages sent via the Apptentive website to this user.
 
 @return The number of unread messages.
 */
- (NSUInteger)unreadMessageCount;


/**
 Returns a "badge" than can be used as a UITableViewCell accessoryView to indicate the current number of unread messages.
 
 To keep this value updated, your view controller will must register for `ATMessageCenterUnreadCountChangedNotification`
 and reload the table view cell when a notification is received.
 
 @param apptentiveHeart A Boolean value indicating whether to include a heart logo adjacent to the number.
 
 @return A badge view suitable for use as a table view cell accessory view.
 */
- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart;

/**
 Forwards a push notification from your application delegate to Apptentive Connect.
 
 If the push notification originated from Apptentive, Message Center will be presented from the view controller.
 
 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;

/**
 Deprecated in 2.0.0 in favor of the better-named `canShowInteractionForEvent:`

 @param event A string representing the name of the event.

 @return `YES` if the event will show an interaction, `NO` otherwise.
*/
- (BOOL)willShowInteractionForEvent:(NSString *)event DEPRECATED_ATTRIBUTE;

/**
Returns a Boolean value indicating whether the given event will cause an Interaction to be shown.
 
 For example, returns YES if a survey is ready to be shown the next time you engage your survey-targeted event. You can use this method to hide a "Show Survey" button in your app if there is no survey to take.
 
 @param event A string representing the name of the event.
 
 @return `YES` if the event will show an interaction, `NO` otherwise.
 */
- (BOOL)canShowInteractionForEvent:(NSString *)event;

/**
 Shows interaction UI, if applicable, related to a given event.
 
 For example, if you have an upgrade message to display on app launch, you might call with event label set to
 `@"app.launch"` here, along with the view controller an upgrade message might be displayed from.
 
 @param event A string representing the name of the event.
 @param viewController A view controller Apptentive UI may be presented from.
 
 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController;

/**
 Shows interaction UI, if applicable, related to a given event, and attaches the specified custom data to the event.
 
 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param viewController A view controller Apptentive UI may be presented from.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
*/
- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController;

/**
 Shows interaction UI, if applicable, related to a given event. Attaches the specified custom data to the event along with the specified extended data.
 
 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param extendedData An array of dictionaries with specific Apptentive formatting. For example, [ATConnect extendedDataDate:[NSDate date]].
 @param viewController A view controller Apptentive UI may be presented from.
 
 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

/**
 Dismisses Message Center.
 
 @param animated `YES` to animate the dismissal, otherwise `NO`.
 @param completion A block called at the conclusion of the message center being dismissed.
 
 @discussion Under normal circumstances, Message Center will be dismissed by the user tapping the Close button, so it is not necessary to call this method.
 */
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

#elif TARGET_OS_MAC

///---------------------------
/// @name Presenting UI (OS X)
///---------------------------
/**
 Presents a feedback window (OS X framework only).
 
 @param sender The originator of the action.
 */
- (IBAction)showFeedbackWindow:(id)sender;
#endif

///--------------------
/// @name Extended Data for Events
///--------------------

/**
 Used to specify a point in time in an event's extended data.
 
 @param date A date and time to be included in an event's extended data.
 
 @return An extended data dictionary representing a point in time, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataDate:(NSDate *)date;

/**
 Used to specify a geographic coordinate in an event's extended data.
 
 @param latitude A location's latitude coordinate.
 @param longitude A location's longitude coordinate.
 
 @return An extended data dictionary representing a geographic coordinate, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude;

/**
 Used to specify a commercial transaction (incorporating multiple items) in an event's extended data.
 
 @param transactionID The transaction's ID.
 @param affiliation The store or affiliation from which this transaction occurred.
 @param revenue The transaction's revenue.
 @param shipping The transaction's shipping cost.
 @param tax Tax on the transaction.
 @param currency Currency for revenue/shipping/tax values.
 @param commerceItems An array of commerce items contained in the transaction. Create commerce items with [ATConnect extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:].
 
 @return An extended data dictionary representing a commerce transaction, to be included in an event's extended data.
  */
+ (NSDictionary *)extendedDataCommerceWithTransactionID:(NSString *)transactionID
											affiliation:(NSString *)affiliation
												revenue:(NSNumber *)revenue
											   shipping:(NSNumber *)shipping
													tax:(NSNumber *)tax
											   currency:(NSString *)currency
										  commerceItems:(NSArray *)commerceItems;

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
+ (NSDictionary *)extendedDataCommerceItemWithItemID:(NSString *)itemID
												name:(NSString *)name
											category:(NSString *)category
											   price:(NSNumber *)price
											quantity:(NSNumber *)quantity
											currency:(NSString *)currency;


///-------------------------------------
/// @name Attach Text, Images, and Files
///-------------------------------------

/**
 Attaches text to the user's feedback.
 
 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.
 
 @param text The text to attach to the user's feedback as a file.
 */
- (void)sendAttachmentText:(NSString *)text;

/**
 Attaches an image the user's feedback.
 
 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.
 
 @param image The image to attach to the user's feedback as a file.
 */
- (void)sendAttachmentImage:(UIImage *)image;

/**
 Attaches an arbitrary file to the user's feedback.
 
 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.
 
 @param fileData The contents of the file as data.
 @param mimeType The MIME type of the file data.
 */
- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType;

///---------------------------------------
/// @name Add Custom Device or Person Data
///---------------------------------------

/** The name of the app user when communicating with Apptentive. */
@property (nonatomic, copy) NSString *personName;
/** The email address of the app user in form fields and communicating with Apptentive. */
@property (nonatomic, copy) NSString *personEmailAddress;

/**
 Adds custom data associated with the current person.
 
 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.
 
 @param object Custom data of type `NSDate`, `NSNumber`, or `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/**
 Adds custom data associated with the current device.
 
 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.
 
 @param object Custom data of type `NSDate`, `NSNumber`, or `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

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
 Deprecated. Use `-addCustomDeviceData:withKey:` instead.
 
 @warning Deprecated!
 @param object The custom data.
 @param key The key of the data.
 */
- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key DEPRECATED_ATTRIBUTE;

/** Deprecated. Use `-removeCustomDeviceDataWithKey:` instead.
 
 @warning Deprecated!
 @param key The key of the data.
 */
- (void)removeCustomDataWithKey:(NSString *)key DEPRECATED_ATTRIBUTE;

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
/// @name Add Push Notifications
///------------------------------------

/**
 Register for Push Notifications with the given service provider.
 
 Uses the `deviceToken` from `application:didRegisterForRemoteNotificationsWithDeviceToken:`
 
 Only one Push Notification Integration can be added at a time. Setting a Push Notification
 Integration removes all previously set Push Notification Integrations.
 
 @param pushProvider The Push Notification provider with which to register.
 @param deviceToken The device token used to send Remote Notifications.
 **/

- (void)setPushNotificationIntegration:(ATPushProvider)pushProvider withDeviceToken:(NSData *)deviceToken;

@end

/**
 The `ATConnectDelegate` protocol allows your app to override the default behavior when
 the Message Center is launched from an incoming push notification. In most cases the 
 default behavior (which walks the view controller stack from the main window's root view
 controller) will work, but if your app features custom container view controllers, it may
 behave unexpectedly. In that case an object in your app should implement the 
 `ATConnectDelegate` protocol's `-viewControllerForInteractionsWithConnection:` method
 and return the view controller from which to present the Message Center interaction. 
 */
@protocol ATConnectDelegate <NSObject>
@optional

/**
 Returns a view controller from which to present the MessageCenter interaction. 
 
 @param connection The `ATConnect` object that is requesting a view controller to present from.
 
 @return The view controller your app would like the interaction to be presented from.
 */
- (UIViewController *)viewControllerForInteractionsWithConnection:(ATConnect *)connection;

@end

/**
 The `ATNavigationController class is an empty subclass of UINavigationController that
 can be used to target UIAppearance settings specifically to Apptentive UI.
 
 For instance, to override the default `barTintColor` (white) for navigation controllers
 in the Apptentive UI, you would call:

	[[UINavigationBar appearanceWhenContainedIn:[ATNavigationController class], nil].barTintColor = [UIColor magentaColor];

 */
@interface ATNavigationController : UINavigationController
@end
