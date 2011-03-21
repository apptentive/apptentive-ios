//
//  ATConnect.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATConnect : NSObject {
}
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, retain) NSString *appID;

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
