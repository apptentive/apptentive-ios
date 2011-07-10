//
//  ATAppRatingFlow.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#define kATAppRatingDefaultDaysBeforePrompt 30
#define kATAppRatingDefaultUsesBeforePrompt 20
#define kATAppRatingDefaultSignificantEventsBeforePrompt 10
#define kATAppRatingDefaultDaysBeforeRePrompting 5

/*! A workflow for a user either giving feedback on or rating the current
 application. */
@interface ATAppRatingFlow : NSObject 
#if TARGET_OS_IPHONE
    <UIAlertViewDelegate>
#endif
{
@private
    NSString *iTunesAppID;
#if TARGET_OS_IPHONE
    UIAlertView *enjoymentDialog;
    UIAlertView *ratingDialog;
#endif
}

/*! The default singleton constructor. Call with an iTunes Applicaiton ID as
 an NSString */
+ (ATAppRatingFlow *)sharedRatingFlowWithAppID:(NSString *)iTunesAppID;

/*! Days since first app use when the user will first be prompted. 
 Set to 0 to disable. Defaults to kATAppRatingDefaultDaysBeforePrompt.
 */
@property (nonatomic, assign) NSUInteger daysBeforePrompt;

/*! Number of app uses before which the user will first be prompted. 
 Set to 0 to disable. Defaults to kATAppRatingDefaultUsesBeforePrompt.
 */
@property (nonatomic, assign) NSUInteger usesBeforePrompt;

/*! Significant events before the user will be prompted.
 Set to 0 to disable. Defaults to 
 kATAppRatingDefaultSignificantEventsBeforePrompt.
 */
@property (nonatomic, assign) NSUInteger significantEventsBeforePrompt;

/*! Days before the user will be re-prompted after having pressed the
 "Remind Me Later" button.
 Set to 0 to disable. Defaults to kATAppRatingDefaultDaysBeforeRePrompting.
 */
@property (nonatomic, assign) NSUInteger daysBeforeRePrompting;

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
