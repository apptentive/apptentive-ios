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

/*! A workflow for a user either giving feedback on or rating the current
 application. */
@interface ATAppRatingFlow : NSObject
#if TARGET_OS_IPHONE
<SKStoreProductViewControllerDelegate, UIAlertViewDelegate>
#endif
{
@private
	NSString *iTunesAppID;
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

/*! The default singleton constructor. Call with an iTunes Applicaiton ID as
 an NSString */
+ (ATAppRatingFlow *)sharedRatingFlowWithAppID:(NSString *)iTunesAppID;

#if TARGET_OS_IPHONE
/*! 
 Call when the application is done launching. If we should be able to
 prompt for a rating, pass YES for canPromptRating. The viewController is
 the viewController from which a feedback dialog will be shown.
 */
- (void)appDidLaunch:(BOOL)canPromptForRating viewController:(UIViewController *)viewController;

/*!
 Call when the application enters the foreground. If we should be able to
 prompt for a rating, pass YES. 
 
 The viewController is the UIViewController from which a feedback dialog 
 will be shown.
 */
- (void)appDidEnterForeground:(BOOL)canPromptForRating viewController:(UIViewController *)viewController;

/*!
 Call whenever a significant event occurs in the application. So, for example,
 if you want to have a rating show up after the user has played 20 levels of
 a game, you would set significantEventsBeforePrompt to 20, and call this
 after each level.
 
 If we should be able to prompt for a rating when this is called, pass YES.
 
 The viewController is the UIViewController from which a feedback dialog 
 will be shown.
 */
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating viewController:(UIViewController *)viewController;

/*!
 Call whenever you would like to set the application name in the ratings
 dialog, if no application name is set the bundle display name will be 
 used as a default value
 */
-(void)setAppName:(NSString *)appName;

#elif TARGET_OS_MAC
/*! 
 Call when the application is done launching. If we should be able to
 prompt for a rating, pass YES.
 */
- (void)appDidLaunch:(BOOL)canPromptForRating;

/*!
 Call whenever a significant event occurs in the application. So, for example,
 if you want to have a rating show up after the user has played 20 levels of
 a game, you would set significantEventsBeforePrompt to 20, and call this
 after each level.
 
 If we should be able to prompt for a rating when this is called, pass YES.
 */
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating;
#endif


#if TARGET_OS_IPHONE
/*!
 Call if you want to show the enjoyment dialog directly. This enters the flow
 for either bringing up the feedback view or the rating dialog.
 */
- (void)showEnjoymentDialog:(UIViewController *)vc;

/*!
 Call if you want to show the rating dialog directly.
 */
- (IBAction)showRatingDialog:(UIViewController *)vc;
#elif TARGET_OS_MAC
/*!
 Call if you want to show the enjoyment dialog directly. This enters the flow
 for either bringing up the feedback view or the rating dialog.
 */
- (IBAction)showEnjoymentDialog:(id)sender;

/*!
 Call if you want to show the rating dialog directly.
 */
- (IBAction)showRatingDialog:(id)sender;
#endif
@end
