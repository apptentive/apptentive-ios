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
 application */
@interface ATAppRatingFlow : NSObject {
@private
    NSString *iTunesAppID;
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

/*! 
 Call when the application is done launching. If we should be able to
 prompt for a rating, pass YES.
 */
- (void)appDidLaunch:(BOOL)canPromptForRating;

#if TARGET_OS_IPHONE
/*!
 Call when the application enters the foreground. If we should be able to
 prompt for a rating, pass YES.
 */
- (void)appDidEnterForeground:(BOOL)canPromptForRating;
#endif

/*!
 Call whenever a significant event occurs in the application. So, for example,
 if you want to have a rating show up after the user has played 20 levels of
 a game, you would set significantEventsBeforePrompt to 20, and call this
 after each level.
 
 If we should be able to prompt for a rating when this is called, pass YES.
 */
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating;

/*!
 Call if you want to show the rating dialog directly.
 */
- (IBAction)showRatingDialog:(id)sender;
@end
