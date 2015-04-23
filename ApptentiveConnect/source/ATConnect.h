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

#define kATConnectVersionString @"1.7.3"

#if TARGET_OS_IPHONE
#	define kATConnectPlatformString @"iOS"
#elif TARGET_OS_MAC
#	define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

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

/** Keys for supported 3rd-party integrations. */
extern NSString *const ATIntegrationKeyUrbanAirship;
extern NSString *const ATIntegrationKeyKahuna;
extern NSString *const ATIntegrationKeyAmazonSNS;
extern NSString *const ATIntegrationKeyParse;

/**
 `ATConnect` is a singleton which is used as the main point of entry for the Apptentive service.
 
 ## Configuration
 
 On first use, you'll want to set the API key, you'd do that like so:
 
     [[ATConnect sharedConnection].apiKey = @"your API key here";
 
 ## Engagement Events
 
 The Ratings Prompt and other Apptentive interactions are targeted to certain Apptentive events. For example,
 you could decide to show the Ratings Prompt at the event user_completed_level. You can then, later,
 reconfigure the Ratings Prompt interaction to show at user_logged_in.
 
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
 
 ## 3rd Party Integration
 
 There are two constant keys for currently supported third party integrations:
 
 * `ATIntegrationKeyUrbanAirship` - For Urban Airship
 * `ATIntegrationKeyAmazonSNS` - For Amazon SNS
 * `ATIntegrationKeyKahuna` - For Kahuna
 * `ATIntegrationKeyParse` - For Parse
 */
@interface ATConnect : NSObject {
@private
#if TARGET_OS_IPHONE
	UIColor *tintColor;
#elif TARGET_OS_MAC
	ATFeedbackWindowController *feedbackWindowController;
#endif
	NSMutableDictionary *customPersonData;
	NSMutableDictionary *customDeviceData;
	NSMutableDictionary *integrationConfiguration;
	NSString *apiKey;
	BOOL showEmailField;
	NSString *initialUserName;
	NSString *initialUserEmailAddress;
	NSString *customPlaceholderText;
	BOOL useMessageCenter;
}

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


///---------------------------------
/// @name Interface Customization
///---------------------------------
/** Toggles the display of an email field in the message panel. `YES` by default. */
@property (nonatomic, assign) BOOL showEmailField;
/** Set this if you want some custom text to appear as a placeholder in the feedback text box. */
@property (nonatomic, copy) NSString *customPlaceholderText;
/** 
 Set this to NO if you don't want to use Message Center, and instead just want unidirectional in-app feedback.
 
 Deprecated in 1.1.1 in favor of server-based configuration of Message Center.
 */
@property (nonatomic, assign) BOOL useMessageCenter DEPRECATED_ATTRIBUTE;
/** 
 Set this to NO to disable Message Center locally on the first launch of your app.
 
 @note This setting will be overridden by server-based configuration when it is downloaded.
 */
@property (nonatomic, assign) BOOL initiallyUseMessageCenter;
/**
 Set this to NO to hide Apptentive branding locally on the first launch of your app.
 
 @note This setting will be overridden by server-based configuration when it is downloaded.
 */
@property (nonatomic, assign) BOOL initiallyHideBranding;
#if TARGET_OS_IPHONE
/**
 A tint color to use in Apptentive-specific UI.
 
 Overrides the default tintColor acquired from your app, in case you're using one that doesn't look great
 with Apptentive-specific UI.
 */
@property (nonatomic, retain) UIColor *tintColor;
#endif


#if TARGET_OS_IPHONE

///--------------------
/// @name Presenting UI
///--------------------

/**
 Presents Message Center from a given view controller.
 
 @param viewController The view controller to present the Message Center from.
 */
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController;

/**
 Presents Message Center from a given view controller with custom data.
 
 @param viewController The view controller to present the Message Center from.
 @param customData A dictionary of key/value pairs to be associated with any messages sent via Message Center.
 */
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;

/**
 Returns the current number of unread messages in Message Center.
 
 These are the messages sent via the Apptentive website to this user.
 */
- (NSUInteger)unreadMessageCount;

/**
 Forwards a push notification from your application delegate to Apptentive Connect.
 
 If the push notification originated from Apptentive, Message Center will be presented from the view controller.
 
 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;

/**
 Returns YES if engaging the given event will cause an Interaction to be shown, otherwise returns NO.
 
 For example, returns YES if a survey is ready to be shown the next time you engage your survey-targeted event.
 You can use this method to hide a "Show Survey" button in your app if there is no survey to take.
 
 @param event A string representing the name of the event.
 */
- (BOOL)willShowInteractionForEvent:(NSString *)event;

/** 
 Shows interaction UI, if applicable, related to a given event.
 
 For example, if you have an upgrade message to display on app launch, you might call with event label set to
 `@"app.launch"` here, along with the view controller an upgrade message might be displayed from.
 
 Returns whether or not an interaction was successfully found and run.
 
 @param event A string representing the name of the event.
 @param viewController A view controller Apptentive UI may be presented from.
 */
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController;

/**
 Engages an event along with custom data about that event. Interaction UI may be shown, if applicable, for the event.
 
 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param viewController A view controller Apptentive UI may be presented from.
 */
- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController;

/**
 Engages an event along with custom data and extended data about that event. Interaction UI may be shown, if applicable, for the event.
 
 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param extendedData An array of dictionaries with specific Apptentive formatting. For example, [ATConnect extendedDataDate:[NSDate date]].
 @param viewController A view controller Apptentive UI may be presented from.
 */
- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

/**
 Dismisses the message center. You normally won't need to call this.
 
 @param animated `YES` to animate the dismissal, otherwise `NO`.
 @param completion A block called at the conclusion of the message center being dismissed.
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
 Extended data dictionary representing a point in time, to be included in an event's extended data.
 
 @param date A date and time to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataDate:(NSDate *)date;

/**
 Extended data dictionary representing a location, to be included in an event's extended data.
 
 @param latitude A location's latitude coordinate.
 @param longitude A location's longitude coordinate.
 */
+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude;

/**
 Extended data dictionary representing a commerce transaction, to be included in an event's extended data.
 
 @param transactionID The transaction's ID.
 @param affiliation The store or affiliation from which this transaction occurred.
 @param revenue The transaction's revenue.
 @param shipping The transaction's shipping cost.
 @param tax Tax on the transaction.
 @param currency Currency for revenue/shipping/tax values.
 @param commerceItems An array of commerce items contained in the transaction. Create commerce items with [ATConnect extendedDataCommerceItem...].
 */
+ (NSDictionary *)extendedDataCommerceWithTransactionID:(NSString *)transactionID
											affiliation:(NSString *)affiliation
												revenue:(NSNumber *)revenue
											   shipping:(NSNumber *)shipping
													tax:(NSNumber *)tax
											   currency:(NSString *)currency
										  commerceItems:(NSArray *)commerceItems;

/**
 Extended data dictionary representing a single item in a commerce transaction, to be included in an event's extended data.
 
 @param itemID The transaction item's ID.
 @param name The transaction item's name.
 @param category The transaction item's category.
 @param price The individual item price.
 @param quantity The number of units purchased.
 @param currency Currency for price.
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

/** The initial name of the app user when communicating with Apptentive. */
@property (nonatomic, copy) NSString *initialUserName;
/** The initial email address of the app user in form fields and communicating with Apptentive. */
@property (nonatomic, copy) NSString *initialUserEmailAddress;

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
/// @name Integrate With Other Services
///------------------------------------

/** 
 Adds a custom configuration for a 3rd-party integration service.
 
 @param integration The name of the integration.
 @param configuration The service-specific configuration keys and values.
 */
- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration;

/**
 Adds a device token for a 3rd-party integration service.
 
 @param integration The name of the integration.
 @param deviceToken The device token expected by the integration.
 */
- (void)addIntegration:(NSString *)integration withDeviceToken:(NSData *)deviceToken;

/**
 Removes a 3rd-party integration with the given name.
 
 @param integration The name of the integration.
 */
- (void)removeIntegration:(NSString *)integration;

/**
 Adds Urban Airship integration with the given device token.
 
 @param deviceToken The device token expected by Urban Airship.
 */
- (void)addUrbanAirshipIntegrationWithDeviceToken:(NSData *)deviceToken;

/**
 Adds Amazon Web Services (AWS) Simple Notification Service (SNS) integration with the given device token.
 
 @param deviceToken The device token expected by AWS SNS.
 */
- (void)addAmazonSNSIntegrationWithDeviceToken:(NSData *)deviceToken;

/**
 Adds Parse integration with the given device token.
 
 @param deviceToken The device token expected by Parse.
 */
- (void)addParseIntegrationWithDeviceToken:(NSData *)deviceToken;

@end
