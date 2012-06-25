//
//  ATUtilities.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#define kApptentiveHostName @"apptentive.com"

@interface ATUtilities : NSObject
#if TARGET_OS_IPHONE
+ (UIImage *)imageByTakingScreenshot;
+ (UIImage *)imageByRotatingImage:(UIImage *)image byRadians:(CGFloat)radians;
+ (UIImage *)imageByScalingImage:(UIImage *)image toSize:(CGSize)size scale:(CGFloat)contentScale fromITouchCamera:(BOOL)isFromITouchCamera;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
#elif TARGET_OS_MAC
+ (NSString *)currentMachineName;
+ (NSString *)currentSystemName;
+ (NSString *)currentSystemVersion;
+ (NSData *)pngRepresentationOfImage:(NSImage *)image;
#endif

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string;
+ (NSString *)randomStringOfLength:(NSUInteger)length;

+ (void)uniquifyArray:(NSMutableArray *)array;
+ (NSString *)stringRepresentationOfDate:(NSDate *)date;
@end

CGRect ATCGRectOfEvenSize(CGRect inRect);

