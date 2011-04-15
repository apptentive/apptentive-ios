//
//  ATUtilities.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kApptentiveHostName @"apptentive.com"

@interface ATUtilities : NSObject {
    
}
+ (UIImage *)imageByTakingScreenshot;
+ (UIImage *)imageByRotatingImage:(UIImage *)image byRadians:(CGFloat)radians;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (NSString *)stringByEscapingForURLArguments:(NSString *)string;
+ (NSString *)randomStringOfLength:(NSUInteger)length;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
@end

CGRect ATCGRectOfEvenSize(CGRect inRect);

