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
+ (UIViewController *)rootViewControllerForCurrentWindow;

#elif TARGET_OS_MAC
+ (NSData *)pngRepresentationOfImage:(NSImage *)image;
#endif
+ (NSString *)currentMachineName;
+ (NSString *)currentSystemName;
+ (NSString *)currentSystemVersion;
+ (NSString *)currentSystemBuild;

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string;
+ (NSString *)stringByEscapingForPredicate:(NSString *)string;
+ (NSString *)randomStringOfLength:(NSUInteger)length;

+ (void)uniquifyArray:(NSMutableArray *)array;
+ (NSString *)stringRepresentationOfDate:(NSDate *)date;
+ (NSString *)stringRepresentationOfDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone;
+ (NSDate *)dateFromISO8601String:(NSString *)string;

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b;

+ (NSArray *)availableAppLocalizations;
+ (UIImage *)appIcon;

/*! Yes if there is only an app version, rather than an app version + build number in standard Cocoa versioning. */
+ (BOOL)bundleVersionIsMainVersion;
+ (NSString *)appVersionString;
+ (NSString *)buildNumberString;

+ (BOOL)appStoreReceiptExists;
+ (NSString *)appStoreReceiptFileName;

+ (BOOL)dictionary:(NSDictionary *)a isEqualToDictionary:(NSDictionary *)b;
+ (NSTimeInterval)maxAgeFromCacheControlHeader:(NSString *)cacheControl;
+ (BOOL)array:(NSArray *)a isEqualToArray:(NSArray *)b;
+ (NSDictionary *)diffDictionary:(NSDictionary *) new againstDictionary:(NSDictionary *)old;

#if TARGET_OS_IPHONE
+ (UIEdgeInsets)edgeInsetsOfView:(UIView *)view;

+ (BOOL)osVersionGreaterThanOrEqualTo:(NSString *)version;
#endif

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress;

+ (UIViewController *)topViewController;

@end

CGRect ATCGRectOfEvenSize(CGRect inRect);

CGSize ATThumbnailSizeOfMaxSize(CGSize imageSize, CGSize maxSize);

CGRect ATThumbnailCropRectForThumbnailSize(CGSize imageSize, CGSize thumbnailSize);
