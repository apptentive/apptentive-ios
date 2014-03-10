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

#define kATConnectVersionString @"1.2.9"

#if TARGET_OS_IPHONE
#	define kATConnectPlatformString @"iOS"
#elif TARGET_OS_MAC
#	define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

extern NSString *const ATMessageCenterUnreadCountChangedNotification;

/*! Keys for supported 3rd-party integrations. */
extern NSString *const ATIntegrationKeyUrbanAirship;
extern NSString *const ATIntegrationKeyKahuna;

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
	BOOL showTagline;
	BOOL showEmailField;
	NSString *initialUserName;
	NSString *initialUserEmailAddress;
	NSString *customPlaceholderText;
	BOOL useMessageCenter;
}
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, assign) BOOL showTagline;
@property (nonatomic, assign) BOOL showEmailField;
@property (nonatomic, copy) NSString *initialUserName;
@property (nonatomic, copy) NSString *initialUserEmailAddress;
/*! Set this if you want some custom text to appear as a placeholder in the
 feedback text box. */
@property (nonatomic, copy) NSString *customPlaceholderText;
/*! Set this to NO if you don't want to use Message Center, and instead just want unidirectional in-app feedback.
 Deprecated in 1.1.1 in favor of server-based configuration of Message Center. */
@property (nonatomic, assign) BOOL useMessageCenter DEPRECATED_ATTRIBUTE;
/*! Set this to NO to disable Message Center locally on the first launch of your app.
Note, though, that Message Center setting will be overridden by server-based configuration when it is downloaded. */
@property (nonatomic, assign) BOOL initiallyUseMessageCenter;
#if TARGET_OS_IPHONE
/*! Overrides the default tintColor acquired from your app, in case you're using one that doesn't
    look great. */
@property (nonatomic, retain) UIColor *tintColor;
#endif

+ (ATConnect *)sharedConnection;

#if TARGET_OS_IPHONE

- (void)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
- (NSUInteger)unreadMessageCount;

/*!
 Forward push notifications from your application delegate to Apptentive.
 If the push notification was sent by Apptentive, Message Center will be presented from the view controller.
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;

/*! 
 Call with a specific code point where interactions should happen.
 
 For example, if you have an upgrade message to display on app launch, you might call with codePoint set to 
 @"app.launch" here, along with the view controller an upgrade message might be displayed from.
 
 Returns whether or not an interaction was successfully found and run.
 */
- (BOOL)engage:(NSString *)codePoint fromViewController:(UIViewController *)viewController;

/*!
 * Dismisses the message center. You normally won't need to call this.
 */
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

#elif TARGET_OS_MAC
/*!
 * Presents a feedback window.
 */
- (IBAction)showFeedbackWindow:(id)sender;
#endif

/*!
 * Attach text, images, or files to the user's feedback.
 * These attachments will appear in your online Apptentive dashboard,
 * but will *not* appear in Message Center on the device.
 */
- (void)sendAttachmentText:(NSString *)text;
- (void)sendAttachmentImage:(UIImage *)image;
- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType;

/*! Adds an additional data field to any feedback sent. Object should be an NSDate, NSNumber, or NSString. */
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/*! Removes an additional data field from the feedback sent. */
- (void)removeCustomPersonDataWithKey:(NSString *)key;
- (void)removeCustomDeviceDataWithKey:(NSString *)key;

/*! Deprecated. Use addCustomDeviceData:withKey: instead. */
- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key DEPRECATED_ATTRIBUTE;
/*! Deprecated. Use removeCustomDeviceDataWithKey: instead. */
- (void)removeCustomDataWithKey:(NSString *)key DEPRECATED_ATTRIBUTE;

/*! Add or remove a token for 3rd-party integration services. */
- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration;
- (void)removeIntegration:(NSString *)integration;

@end
