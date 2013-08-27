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

#define kATConnectVersionString @"1.0.1"

#if TARGET_OS_IPHONE
#	define kATConnectPlatformString @"iOS"
#elif TARGET_OS_MAC
#	define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

extern NSString *const ATMessageCenterUnreadCountChangedNotification;


@interface ATConnect : NSObject {
@private
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
	ATFeedbackWindowController *feedbackWindowController;
#endif
	NSMutableDictionary *customPersonData;
	NSMutableDictionary *customDeviceData;
	NSString *apiKey;
	BOOL showTagline;
	BOOL showEmailField;
	NSString *initialUserName;
	NSString *initialUserEmailAddress;
	NSString *customPlaceholderText;
}
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, assign) BOOL showTagline;
@property (nonatomic, assign) BOOL showEmailField;
@property (nonatomic, copy) NSString *initialUserName;
@property (nonatomic, copy) NSString *initialUserEmailAddress;
/*! Set this if you want some custom text to appear as a placeholder in the
 feedback text box. */
@property (nonatomic, copy) NSString *customPlaceholderText;

+ (ATConnect *)sharedConnection;

#if TARGET_OS_IPHONE

- (void)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (NSUInteger)unreadMessageCount;

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

/*! Adds an additional data field to any feedback sent. object should be an NSDate, NSNumber, or NSString. */
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/*! Removes an additional data field from the feedback sent. */
- (void)removeCustomPersonDataWithKey:(NSString *)key;
- (void)removeCustomDeviceDataWithKey:(NSString *)key;

/*! Deprecated. Use addCustomDeviceData:withKey: instead. */
- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key DEPRECATED_ATTRIBUTE;
/*! Deprecated. Use removeCustomDeviceDataWithKey: instead. */
- (void)removeCustomDataWithKey:(NSString *)key DEPRECATED_ATTRIBUTE;
@end
