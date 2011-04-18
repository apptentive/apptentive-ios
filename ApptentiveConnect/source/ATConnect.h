//
//  ATConnect.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kATConnectVersionString @"1.0"
#define kATConnectPlatformString @"iOS"

@interface ATConnect : NSObject {
}
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, assign) BOOL showKeyboardAccessory;
@property (nonatomic, assign) BOOL shouldTakeScreenshot;

+ (ATConnect *)sharedConnection;

/*! 
 * Presents a feedback controller from the given view controller. The feedback
 * controller will be presented with 
 * [viewController presentModalViewController:…].
 */
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController;

/*!
 * Returns the NSBundle corresponding to the bundle containing ATConnect's
 * images, xibs, strings files, etc.
 */
+ (NSBundle *)resourceBundle;
@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls 
    localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString *comment);
