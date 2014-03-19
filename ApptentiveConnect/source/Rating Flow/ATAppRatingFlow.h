//
//  ATAppRatingFlow.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

/*! Notification sent when the user has agreed to rate the application. */
extern NSString *const ATAppRatingFlowUserAgreedToRateAppNotification;

/*! A workflow for a user either giving feedback on or rating the current
 application. */
@interface ATAppRatingFlow : NSObject
#if TARGET_OS_IPHONE
<SKStoreProductViewControllerDelegate, UIAlertViewDelegate>
#endif
{
@private
	NSString *appID;
#if TARGET_OS_IPHONE
	UIAlertView *enjoymentDialog;
	UIAlertView *ratingDialog;
#endif
	
	NSUInteger daysBeforePrompt;
	NSUInteger usesBeforePrompt;
	NSUInteger significantEventsBeforePrompt;
	NSUInteger daysBeforeRePrompting;
	
	NSDate *lastUseOfApp;
}
/*! 
 Set to a custom app name if you'd like to use something other than the bundle display name.
 Deprecated in 1.0.1 in favor of server-based configuration of the app display name. 
 */
@property (nonatomic, copy) NSString *appName DEPRECATED_ATTRIBUTE;

@property (nonatomic, copy) NSString *appID;

/*! The default singleton constructor. */
+ (ATAppRatingFlow *)sharedRatingFlow;

+ (ATAppRatingFlow *)sharedRatingFlowWithAppID:(NSString *)iTunesAppID;

#if TARGET_OS_IPHONE
/*!
 Will show the ratings flow from the given viewController if the conditions to do so are met.
 Returns BOOL indicating if the ratings flow was shown or not.
 */
- (BOOL)showRatingFlowFromViewControllerIfConditionsAreMet:(UIViewController *)viewController;

#elif TARGET_OS_MAC
- (void)showRatingFlowIfConditionsAreMet;

/*! 
 Call when the application is done launching. If we should be able to
 prompt for a rating, pass YES.
 */
- (void)appDidLaunch:(BOOL)canPromptForRating;
#endif

/*!
 Call whenever a significant event occurs in the application. So, for example,
 if you want to have a rating show up after the user has played 20 levels of
 a game, you would set significantEventsBeforePrompt to 20, and call this
 after each level.
 */
- (void)logSignificantEvent;

/*!
 Call to open your app's page on the App Store or Mac App Store.
 This method can be used to power, for example, a "Rate this app" button in your settings screen.
 It opens the app store directly, without the normal Apptentive Ratings Flow.
 If the app store is manually opened, the Rating Flow will not prompt again for this version.
 Depending on the iOS version, the App Store will either be opened via the App Store app or as
 a Store Kit view inside your app.
 */
- (void)openAppStore;


/*!
 Call to know if the user have already oppened the App Store or Mac App Store to rate your
 application.
*/
- (BOOL)userAlreadyRatedApp;

@end
