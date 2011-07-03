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

#define kATConnectVersionString @"1.0"

#if TARGET_OS_IPHONE
#define kATConnectPlatformString @"iOS"
#elif TARGET_OS_MAC
#define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

@interface ATConnect : NSObject {
#if !TARGET_OS_IPHONE
    ATFeedbackWindowController *feedbackWindowController;
#endif
}
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, assign) BOOL showKeyboardAccessory;
@property (nonatomic, assign) BOOL shouldTakeScreenshot;

+ (ATConnect *)sharedConnection;

#if TARGET_OS_IPHONE
/*! 
 * Presents a feedback controller from the given view controller. The feedback
 * controller will be presented with 
 * [viewController presentModalViewController:…].
 */
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController;
#elif TARGET_OS_MAC
/*!
 * Presents a feedback window.
 */
- (IBAction)showFeedbackWindow:(id)sender;
- (IBAction)showFeedbackWindowForFeedback:(id)sender;
- (IBAction)showFeedbackWindowForQuestion:(id)sender;
- (IBAction)showFeedbackWindowForBugReport:(id)sender;
#endif

/*!
 * Returns the NSBundle corresponding to the bundle containing ATConnect's
 * images, xibs, strings files, etc.
 */
+ (NSBundle *)resourceBundle;
@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls 
    localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString *comment);
