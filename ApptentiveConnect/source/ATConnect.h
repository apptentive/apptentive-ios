//
//  ATConnect.h
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATConnect : NSObject {
}
+ (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController;
+ (NSBundle *)resourceBundle;
@end
