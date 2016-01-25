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
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
+ (UIViewController *)rootViewControllerForCurrentWindow;
+ (UIViewController *)topViewController;
+ (UIImage *)appIcon;
#elif TARGET_OS_MAC
+ (NSData *)pngRepresentationOfImage:(NSImage *)image;
#endif

+ (NSString *)currentMachineName;
+ (NSString *)currentSystemName;
+ (NSString *)currentSystemVersion;
+ (NSString *)currentSystemBuild;
+ (NSUUID *)currentDeviceID;

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string;
+ (NSString *)stringByEscapingForPredicate:(NSString *)string;
+ (NSString *)randomStringOfLength:(NSUInteger)length;

+ (NSString *)stringRepresentationOfDate:(NSDate *)date;

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b;

+ (NSArray *)availableAppLocalizations;

+ (NSString *)appBundleVersionString;
+ (NSString *)appBundleShortVersionString;
+ (NSString *)appVersionString;
+ (NSString *)buildNumberString;

+ (BOOL)appStoreReceiptExists;
+ (NSString *)appStoreReceiptFileName;

+ (BOOL)dictionary:(NSDictionary *)a isEqualToDictionary:(NSDictionary *)b;
+ (NSTimeInterval)maxAgeFromCacheControlHeader:(NSString *)cacheControl;
+ (NSDictionary *)diffDictionary:(NSDictionary *) new againstDictionary:(NSDictionary *)old;

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress;

@end

CGRect ATCGRectOfEvenSize(CGRect inRect);

//CGSize ATThumbnailSizeOfMaxSize(CGSize imageSize, CGSize maxSize);
//
//CGRect ATThumbnailCropRectForThumbnailSize(CGSize imageSize, CGSize thumbnailSize);
