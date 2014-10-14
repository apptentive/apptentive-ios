//
//  ATUtilities.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATUtilities.h"
#import <QuartzCore/QuartzCore.h>
#if !TARGET_OS_IPHONE
#import <Carbon/Carbon.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#endif
#include <stdlib.h>
#if TARGET_OS_IPHONE
#import <sys/utsname.h>
#endif

#define KINDA_EQUALS(a, b) (fabs(a - b) < 0.1)
#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

static NSDateFormatter *dateFormatter = nil;

@interface ATUtilities (Private)
+ (void)setupDateFormatters;
@end

@implementation ATUtilities

+ (UIImage *)imageByTakingScreenshot {
	return [self imageByTakingScreenshotExcludingWindow:nil];
}

#if TARGET_OS_IPHONE
// From QA1703:
// http://developer.apple.com/library/ios/#qa/qa1703/_index.html
// with changes to account for the application frame.
//TODO: Use iOS 7 snapshotting API.
+ (UIImage *)imageByTakingScreenshotExcludingWindow:(UIWindow *)excludedWindow {
	// Create a graphics context with the target size
	// On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
	// On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	CGSize imageSize = applicationFrame.size;
	UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Iterate over every window from back to front
	for (UIWindow *window in [[UIApplication sharedApplication] windows])  {
		if (window == excludedWindow) {
			continue;
		}
		
		if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
			// -renderInContext: renders in the coordinate space of the layer,
			// so we must first apply the layer's geometry to the graphics context
			CGContextSaveGState(context);
			// Adjust to account for the application frame offset.
			CGContextTranslateCTM(context, -applicationFrame.origin.x, -applicationFrame.origin.y);
			// Center the context around the window's anchor point
			CGContextTranslateCTM(context, [window center].x, [window center].y);
			// Apply the window's transform about the anchor point
			CGContextConcatCTM(context, [window transform]);
			// Offset by the portion of the bounds left of and above the anchor point
			CGContextTranslateCTM(context,
								  -[window bounds].size.width * [[window layer] anchorPoint].x,
								  -[window bounds].size.height * [[window layer] anchorPoint].y);
			
			// Render the layer hierarchy to the current context
			[[window layer] renderInContext:context];
			
			// Restore the context
			CGContextRestoreGState(context);
		}
	}
	
	// Retrieve the screenshot image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	return image;
}

+ (UIImage *)imageByTakingScreenshotIncludingBlankStatusBarArea:(BOOL)includeStatusBar excludingWindow:(UIWindow *)window {
	UIImage *screenshot = [self imageByTakingScreenshotExcludingWindow:window];

	if (includeStatusBar) {
		CGSize screenSize = [[UIScreen mainScreen] bounds].size;
		UIGraphicsBeginImageContextWithOptions(screenSize, NO, 0);
		
		CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
		CGFloat statusBarHeight = MIN(statusBarSize.width, statusBarSize.height);
		
		CGPoint origin;
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		switch (orientation) {
			case UIInterfaceOrientationPortrait:
				origin = CGPointMake(0, statusBarHeight);
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				origin = CGPointMake(0, 0);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				origin = CGPointMake(statusBarHeight, 0);
				break;
			case UIInterfaceOrientationLandscapeRight:
				origin = CGPointMake(0, 0);
				break;
			default:
				origin = CGPointZero;
				break;
		}
		[screenshot drawAtPoint:origin];
		UIImage *screenshotPlusStatusBar = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		screenshot = screenshotPlusStatusBar;
	}
	
	return screenshot;
}

+ (UIImage *)imageByRotatingImage:(UIImage *)image toInterfaceOrientation:(UIInterfaceOrientation)orientation {
	UIImageOrientation imageOrientation = UIImageOrientationUp;
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationRight;
			break;
		case UIInterfaceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationLeft;
			break;
		default:
			break;
	}
	UIImage *rotated = [[[UIImage alloc] initWithCGImage:[image CGImage] scale:1 orientation:imageOrientation] autorelease];
	
	return rotated;
}

+ (UIImage *)imageByRotatingImage:(UIImage *)image byRadians:(CGFloat)radians {
	UIImage *result = nil;
	
	if (KINDA_EQUALS(radians, 0.0) || KINDA_EQUALS(radians, M_PI * 2.0)) {
		return image;
	}
	
	CGAffineTransform t = CGAffineTransformIdentity;
	CGSize size = image.size;
	BOOL onSide = NO;
	
	if (KINDA_EQUALS(fabsf(radians), M_PI)) {
		// Upside down, weeeee.
		t = CGAffineTransformTranslate(t, size.width, size.height);
		t = CGAffineTransformRotate(t, M_PI);
	} else if (KINDA_EQUALS(radians, M_PI * 0.5)) {
		// Home button on right. Image is rotated right 90 degrees.
		onSide = YES;
		size = CGSizeMake(size.height, size.width);
		t = CGAffineTransformRotate(t, M_PI * 0.5);
		t = CGAffineTransformScale(t, size.height/size.width, size.width/size.height);
		t = CGAffineTransformTranslate(t, 0.0, -size.height);
	} else if (KINDA_EQUALS(radians, -1.0 * M_PI * 0.5)) {
		// Home button on left. Image is rotated left 90 degrees.
		onSide = YES;
		size = CGSizeMake(size.height, size.width);\
		t = CGAffineTransformRotate(t, -1.0 * M_PI * 0.5);
		t = CGAffineTransformScale(t, size.height/size.width, size.width/size.height);
		t = CGAffineTransformTranslate(t, -size.width, 0.0);
	}
	
	UIGraphicsBeginImageContext(size);
	CGRect r = CGRectMake(0.0, 0.0, size.width, size.height);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (onSide) {
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0.0, -size.height);
	} else {
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0.0, -size.height);
	}
	CGContextConcatCTM(context, t);
	CGContextDrawImage(context, r, image.CGImage);
	
	result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}

+ (UIImage *)imageByScalingImage:(UIImage *)image toSize:(CGSize)size scale:(CGFloat)contentScale fromITouchCamera:(BOOL)isFromITouchCamera {
	UIImage *result = nil;
	CGImageRef imageRef = nil;
	size_t samplesPerPixel, bytesPerRow, bitsPerComponent;
	CGFloat newHeight, newWidth;
	CGRect newRect;
	CGContextRef bitmapContext = nil;
	CGImageRef newRef = nil;
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGImageAlphaInfo newAlphaInfo;
	CGColorSpaceRef colorSpaceRef;
	
	imageRef = [image CGImage];
	
	samplesPerPixel = 4;
	
	size = CGSizeMake(floor(size.width), floor(size.height));
	newWidth = size.width;
	newHeight = size.height;
	
	// Rotate and scale based on orientation.
	if (image.imageOrientation == UIImageOrientationUpMirrored) { // EXIF 2
		// Image is mirrored horizontally.
		transform = CGAffineTransformMakeTranslation(newWidth, 0);
		transform = CGAffineTransformScale(transform, -1, 1);
	} else if (image.imageOrientation == UIImageOrientationDown) { // EXIF 3
		// Image is rotated 180 degrees.
		transform = CGAffineTransformMakeTranslation(newWidth, newHeight);
		transform = CGAffineTransformRotate(transform, DEG_TO_RAD(180));
	} else if (image.imageOrientation == UIImageOrientationDownMirrored) { // EXIF 4
		// Image is mirrored vertically.
		transform = CGAffineTransformMakeTranslation(0, newHeight);
		transform = CGAffineTransformScale(transform, 1.0, -1.0);
	} else if (image.imageOrientation == UIImageOrientationLeftMirrored) { // EXIF 5
		// Image is mirrored horizontally then rotated 270 degrees clockwise.
		transform = CGAffineTransformRotate(transform, DEG_TO_RAD(90));
		transform = CGAffineTransformScale(transform, -newHeight/newWidth,  newWidth/newHeight);
		transform = CGAffineTransformTranslate(transform, -newWidth, -newHeight);
	} else if (image.imageOrientation == UIImageOrientationLeft) { // EXIF 6
		// Image is rotated 270 degrees clockwise.
		transform = CGAffineTransformRotate(transform, DEG_TO_RAD(-90));
		transform = CGAffineTransformScale(transform, newHeight/newWidth,  newWidth/newHeight);
		transform = CGAffineTransformTranslate(transform, -newWidth, 0);
	} else if (image.imageOrientation == UIImageOrientationRightMirrored) { // EXIF 7
		// Image is mirrored horizontally then rotated 90 degrees clockwise.
		transform = CGAffineTransformRotate(transform, DEG_TO_RAD(-90));
		transform = CGAffineTransformScale(transform, -newHeight/newWidth,  newWidth/newHeight);
	} else if (image.imageOrientation == UIImageOrientationRight) { // EXIF 8
		// Image is rotated 90 degrees clockwise.
		transform = CGAffineTransformRotate(transform, DEG_TO_RAD(90));
		transform = CGAffineTransformScale(transform, newHeight/newWidth,  newWidth/newHeight);
		transform = CGAffineTransformTranslate(transform, 0.0, -newHeight);
	}
	newRect = CGRectIntegral(CGRectMake(0.0, 0.0, newWidth, newHeight));
	
	bytesPerRow = samplesPerPixel * newWidth;
	newAlphaInfo = kCGImageAlphaPremultipliedFirst;
	bitsPerComponent = 8;
	colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	
	bitmapContext = CGBitmapContextCreate(NULL, newWidth, newHeight, bitsPerComponent, bytesPerRow, colorSpaceRef, (CGBitmapInfo)newAlphaInfo);
	CGColorSpaceRelease(colorSpaceRef), colorSpaceRef = NULL;
	CGContextSetInterpolationQuality(bitmapContext, kCGInterpolationHigh);
	
	// The iPhone tries to be "smart" about image orientation, and messes it
	// up in the process. Here, UIImageOrientationLeft happens when the 
	// device is held upside down (camera on the end towards the ground).
	// UIImageOrientationRight happens when the camera is in a normal, upright
	// position. In both cases, the image is rotated 180 degrees from what
	// the user actually saw through the image preview.
	if (isFromITouchCamera && (image.imageOrientation == UIImageOrientationRight || image.imageOrientation == UIImageOrientationLeft)) {
		CGContextScaleCTM(bitmapContext, -1.0, -1);
		CGContextTranslateCTM(bitmapContext, -newWidth, -newHeight);
	}
	
	CGContextConcatCTM(bitmapContext, transform);
	CGContextDrawImage(bitmapContext, newRect, imageRef);
	
	newRef = CGBitmapContextCreateImage(bitmapContext);
	result = [UIImage imageWithCGImage:newRef scale:contentScale orientation:UIImageOrientationUp];
	CGContextRelease(bitmapContext);
	CGImageRelease(newRef);
	
	return result;
}

+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView {
	CGAffineTransform t = leafView.transform;
	UIView *s = leafView.superview;
	while (s && s != leafView.window) {
		t = CGAffineTransformConcat(t, s.transform);
		s = s.superview;
	}
	return atan2(t.b, t.a);
}

+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window {
	CGAffineTransform result = CGAffineTransformIdentity;
	do { // once
		if (!window) break;
		
		if ([[window rootViewController] view]) {
			CGFloat rotation = [ATUtilities rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
			result = CGAffineTransformMakeRotation(rotation);
			break;
		}
		
		if ([[window subviews] count]) {
			for (UIView *v in [window subviews]) {
				if (!CGAffineTransformIsIdentity(v.transform)) {
					result = v.transform;
					break;
				}
			}
		}
	} while (NO);
	return result;
}

+ (UIViewController *)rootViewControllerForCurrentWindow {
	UIWindow *window = nil;
	for (UIWindow *tmpWindow in [[UIApplication sharedApplication] windows]) {
		if ([[tmpWindow screen] isEqual:[UIScreen mainScreen]] && [tmpWindow isKeyWindow]) {
			window = tmpWindow;
			break;
		}
	}

	if (window && [window respondsToSelector:@selector(rootViewController)]) {
		UIViewController *vc = [window rootViewController];
		if ([vc respondsToSelector:@selector(presentedViewController)] && [vc presentedViewController]) {
			return [vc presentedViewController];
		}
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		if ([vc respondsToSelector:@selector(modalViewController)] && [vc modalViewController]) {
			return [vc modalViewController];
		}
#		pragma clang diagnostic pop
		return vc;
	} else {
		return nil;
	}
}

+ (UIColor *)contrastingTextColorForBackgroundColor:(UIColor *)backgroundColor {
	const CGFloat *componentColors = CGColorGetComponents(backgroundColor.CGColor);
	
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    
	UIColor *textColor;
	
	if (colorBrightness < 0.5) {
		textColor = [UIColor whiteColor];
    } else {
		textColor = [UIColor blackColor];
    }
	
	return textColor;
}

#elif TARGET_OS_MAC

+ (NSData *)pngRepresentationOfImage:(NSImage *)image {
	CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:nil];
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
	NSData *result = [imageRep representationUsingType:NSPNGFileType properties:nil];
	[imageRep release];
	return result;
}
#endif

+ (NSString *)currentMachineName {
#if TARGET_OS_IPHONE
	struct utsname systemInfo;
	uname(&systemInfo);
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
#elif TARGET_OS_MAC
	char modelBuffer[256];
	size_t sz = sizeof(modelBuffer);
	NSString *result = @"Unknown";
	if (0 == sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0)) {
		modelBuffer[sizeof(modelBuffer) - 1] = 0;
		result = [NSString stringWithUTF8String:modelBuffer];
	}
	return result;
#endif
}

+ (NSString *)currentSystemName {
#if TARGET_OS_IPHONE
	return [[UIDevice currentDevice] systemName];
#elif TARGET_OS_MAC
	NSProcessInfo *info = [NSProcessInfo processInfo];
	NSString *osName = [info operatingSystemName];
	
	if ([osName isEqualToString:@"NSMACHOperatingSystem"]) {
		osName = @"Mac OS X";
	}
	
	return osName;
#endif
}

+ (NSString *)currentSystemVersion {
#if TARGET_OS_IPHONE
	return [[UIDevice currentDevice] systemVersion];
#elif TARGET_OS_MAC
	NSProcessInfo *info = [NSProcessInfo processInfo];
	return [info operatingSystemVersionString];
#endif
}


+ (NSString *)stringByEscapingForURLArguments:(NSString *)string {
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)@"%:/?#[]@!$&'()*+,;=", kCFStringEncodingUTF8);
	return [NSMakeCollectable(result) autorelease];
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
	static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	NSMutableString *result = [NSMutableString stringWithString:@""];
	for (NSUInteger i = 0; i < length; i++) {
		[result appendFormat:@"%c", [letters characterAtIndex:arc4random()%[letters length]]];
	}
	return result;
}

+ (void)uniquifyArray:(NSMutableArray *)array {
	NSUInteger location = [array count];
	for (NSObject *value in [array reverseObjectEnumerator]) {
		location -= 1;
		NSUInteger index = [array indexOfObject:value];
		if (index < location) {
			[array removeObjectAtIndex:location];
		}
	}
}


+ (NSString *)stringRepresentationOfDate:(NSDate *)aDate {
	return [ATUtilities stringRepresentationOfDate:aDate timeZone:[NSTimeZone defaultTimeZone]];
}

+ (NSString *)stringRepresentationOfDate:(NSDate *)aDate timeZone:(NSTimeZone *)timeZone {
	NSString *result = nil;
	@synchronized(self) { // to avoid calendars stepping on themselves
		[ATUtilities setupDateFormatters];
		dateFormatter.timeZone = timeZone;
		NSString *dateString = [dateFormatter stringFromDate:aDate];
		
		NSInteger timeZoneOffset = [timeZone secondsFromGMT];
		NSString *sign = (timeZoneOffset >= 0) ? @"+" : @"-";
		NSInteger hoursOffset = abs(floor(timeZoneOffset/60/60));
		NSInteger minutesOffset = abs((int)floor(timeZoneOffset/60) % 60);
		NSString *timeZoneString = [NSString stringWithFormat:@"%@%.2d%.2d", sign, (int)hoursOffset, (int)minutesOffset];
		
		NSTimeInterval interval = [aDate timeIntervalSince1970];
		double fractionalSeconds = interval - (long)interval;
		
		// This is all necessary because of rdar://10500679 in which NSDateFormatter won't
		// format fractional seconds past two decimal places. Also, strftime() doesn't seem
		// to have fractional seconds on iOS.
		if (fractionalSeconds == 0.0) {
			result = [NSString stringWithFormat:@"%@ %@", dateString, timeZoneString];
		} else {
			NSString *f = [[NSString alloc] initWithFormat:@"%g", fractionalSeconds];
			NSRange r = [f rangeOfString:@"."];
			if (r.location != NSNotFound) {
				NSString *truncatedFloat = [f substringFromIndex:r.location + r.length];
				result = [NSString stringWithFormat:@"%@.%@ %@", dateString, truncatedFloat, timeZoneString];
			} else {
				// For some reason, we couldn't find the decimal place.
				result = [NSString stringWithFormat:@"%@.%ld %@", dateString, (long)(fractionalSeconds * 1000), timeZoneString];
			}
			[f release], f= nil;
		}
	}
	return result;
}

+ (NSDate *)dateFromISO8601String:(NSString *)string {
	BOOL validDate = YES;
	NSDate *result = nil;
	
	NSDate *now = [NSDate date];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	calendar.firstWeekday = 2;
	calendar.timeZone = [NSTimeZone defaultTimeZone];
	
	NSDateComponents *components = [[NSDateComponents alloc] init];
	NSDateComponents *nowComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
	components.calendar = calendar;
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	NSString *ymdString = nil;
	[scanner scanUpToString:@"T" intoString:&ymdString];
	
	if (ymdString && [ymdString length]) {
		NSScanner *ymdScanner = [[NSScanner alloc] initWithString:ymdString];
		do { // once
			NSInteger month = 0;
			NSInteger day = 0;
			NSString *yearString = nil;
			if (![ymdScanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&yearString] || [yearString length] != 4) {
				validDate = NO;
				break;
			}
			components.year = [yearString integerValue];
			if (![ymdScanner scanString:@"-" intoString:NULL]) break;
			if (![ymdScanner scanInteger:&month]) break;
			components.month = month;
			if (![ymdScanner scanString:@"-" intoString:NULL]) break;
			if (![ymdScanner scanInteger:&day]) break;
			components.day = day;
		} while (NO);
		[ymdScanner release], ymdScanner = nil;
	} else {
		[components setYear:[nowComponents year]];
		[components setMonth:[nowComponents month]];
		[components setDay:[nowComponents day]];
	}
	
	if ([scanner scanString:@"T" intoString:NULL]) {
		do { // once
			NSInteger hour = 0;
			NSInteger minute = 0;
			if (![scanner scanInteger:&hour]) {
				validDate = NO;
				break;
			}
			components.hour = hour;
			if (![scanner scanString:@":" intoString:NULL]) break;
			if (![scanner scanInteger:&minute]) break;
			components.minute = minute;
			if (![scanner scanString:@":" intoString:NULL]) break;
			double secondFraction = 0.0;
			if (![scanner scanDouble:&secondFraction]) break;
			components.second = (NSInteger)round(secondFraction);
		} while (NO);
	}
	
	if ([scanner scanString:@"Z" intoString:NULL]) {
		// Use UTC.
		components.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	} else {
		do { // once
			BOOL isPositiveOffset = YES;
			if ([scanner scanString:@"+" intoString:NULL]) {
				isPositiveOffset = YES;
			} else if ([scanner scanString:@"-" intoString:NULL]) {
				isPositiveOffset = NO;
			} else {
				if (![scanner isAtEnd]) {
					validDate = NO;
				}
				break;
			}
			NSInteger hours = 0;
			NSInteger minutes = 0;
			if (!([scanner scanInteger:&hours] && [scanner scanString:@":" intoString:NULL] && [scanner scanInteger:&minutes])) {
				validDate = NO;
				break;
			}
			NSInteger secondsFromGMT = hours*3600 + minutes*60;
			if (!isPositiveOffset) {
				secondsFromGMT = secondsFromGMT * -1;
			}
			components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:secondsFromGMT];
		} while (NO);
	}
	
	[calendar release], calendar = nil;
	[scanner release], scanner = nil;
	if (validDate) {
		result = [components date];
	}
	[components release], components = nil;
	return result;
}

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b {
	return [a compare:b options:NSNumericSearch];
}

+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ATUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedDescending);
}

+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ATUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedAscending);
}

+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ATUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedSame);
}

+ (NSArray *)availableAppLocalizations {
	static NSMutableArray *localAppLocalizations = nil;
	@synchronized(self) {
		if (localAppLocalizations == nil) {
			NSArray *rawLocalizations = [[NSBundle mainBundle] localizations];
			localAppLocalizations = [[NSMutableArray alloc] init];
			for (NSString *loc in rawLocalizations)  {
				NSString *s = [NSLocale canonicalLocaleIdentifierFromString:loc];
				if (![localAppLocalizations containsObject:s]) {
					[localAppLocalizations addObject:s];
				}
			}
		}
	}
	return localAppLocalizations;
}

+ (UIImage *)appIcon {
	static UIImage *iconFile = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSArray *iconFiles = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
		if (!iconFiles) {
			// Asset Catalog app icons
			iconFiles = [NSBundle mainBundle].infoDictionary[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
		}
		
		UIImage *maxImage = nil;
		for (NSString *path in iconFiles) {
			UIImage *image = [UIImage imageNamed:path];
			if (maxImage == nil || maxImage.size.width < image.size.width) {
				if (image.size.width >= 512) {
					// Just in case someone stuck iTunesArtwork in there.
					continue;
				}
				maxImage = image;
			}
		}
		iconFile = [maxImage retain];
	});
	return [[iconFile retain] autorelease];
}

+ (BOOL)bundleVersionIsMainVersion {
	BOOL result = NO;
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleVersion = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];
	NSString *shortVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
	
	if (!shortVersion) {
		result = YES;
	} else if ([shortVersion isEqualToString:bundleVersion]) {
		result = YES;
	}
	return result;
}

+ (NSString *)appVersionString {
	static NSString *appVersionString = nil;
	@synchronized(self) {
		if (appVersionString == nil) {
			if ([ATUtilities bundleVersionIsMainVersion]) {
				appVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
			} else {
				appVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
			}
		}
	}
	return appVersionString;
}

+ (NSString *)buildNumberString {
	static NSString *buildNumberString = nil;
	@synchronized(self) {
		if (buildNumberString == nil) {
			if (![self bundleVersionIsMainVersion]) {
				buildNumberString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
			} else {
				buildNumberString = @"?";
			}
		}
	}
	if ([buildNumberString isEqualToString:@"?"]) {
		return nil;
	} else {
		return buildNumberString;
	}
}

+ (NSTimeInterval)maxAgeFromCacheControlHeader:(NSString *)cacheControl {
	if (cacheControl == nil || [cacheControl rangeOfString:@"max-age"].location == NSNotFound) {
		return 0;
	}
	NSTimeInterval maxAge = 0;
	NSScanner *scanner = [[NSScanner alloc] initWithString:[cacheControl lowercaseString]];
	[scanner scanUpToString:@"max-age" intoString:NULL];
	if ([scanner scanString:@"max-age" intoString:NULL] && [scanner scanString:@"=" intoString:NULL]) {
		if (![scanner scanDouble:&maxAge]) {
			maxAge = 0;
		}
	}
	[scanner release], scanner = nil;
	return maxAge;
}

+ (BOOL)dictionary:(NSDictionary *)a isEqualToDictionary:(NSDictionary *)b {
	BOOL isEqual = NO;
	
	do { // once
		if (a == b) {
			isEqual = YES;
			break;
		}
		if ((a == nil && b != nil) || (a != nil && b == nil)) {
			break;
		}
		if ([a count] != [b count]) {
			break;
		}
		for (NSObject *keyA in a) {
			NSObject *valueB = [b objectForKey:keyA];
			if (valueB == nil) {
				goto done;
			}
			NSObject *valueA = [a objectForKey:keyA];
			if ([valueA isKindOfClass:[NSDictionary class]] && [valueB isKindOfClass:[NSDictionary class]]) {
				BOOL deepEquals = [ATUtilities dictionary:(NSDictionary *)valueA isEqualToDictionary:(NSDictionary *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if ([valueA isKindOfClass:[NSArray class]] && [valueB isKindOfClass:[NSArray class]])  {
				BOOL deepEquals = [ATUtilities array:(NSArray *)valueA isEqualToArray:(NSArray *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if (![valueA isEqual:valueB]) {
				goto done;
			}
		}
		isEqual = YES;
	} while (NO);

done:
	return isEqual;
}

+ (BOOL)array:(NSArray *)a isEqualToArray:(NSArray *)b {
	BOOL isEqual = NO;
	
	do { // once
		if (a == b) {
			isEqual = YES;
			break;
		}
		if ((a == nil && b != nil) || (a != nil && b == nil)) {
			break;
		}
		if ([a count] != [b count]) {
			break;
		}
		NSUInteger index = 0;
		for (NSObject *valueA in a) {
			NSObject *valueB = [b objectAtIndex:index];
			if ([valueA isKindOfClass:[NSDictionary class]] && [valueB isKindOfClass:[NSDictionary class]]) {
				BOOL deepEquals = [ATUtilities dictionary:(NSDictionary *)valueA isEqualToDictionary:(NSDictionary *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if ([valueA isKindOfClass:[NSArray class]] && [valueB isKindOfClass:[NSArray class]])  {
				BOOL deepEquals = [ATUtilities array:(NSArray *)valueA isEqualToArray:(NSArray *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if (![valueA isEqual:valueB]) {
				goto done;
			}
			index++;
		}
		isEqual = YES;
	} while (NO);
	
done:
	return isEqual;
}


#if TARGET_OS_IPHONE
+ (UIEdgeInsets)edgeInsetsOfView:(UIView *)view {
	UIEdgeInsets insets = UIEdgeInsetsZero;
	insets.left = view.frame.origin.x;
	insets.top = view.frame.origin.y;
	if (view.superview) {
		UIView *superview = view.superview;
		insets.bottom = superview.bounds.size.height - view.bounds.size.height - insets.top;
		insets.right = superview.bounds.size.width - view.bounds.size.width - insets.left;
	}
	return insets;
}

+ (BOOL)osVersionGreaterThanOrEqualTo:(NSString *)version {
	return ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending);
}
#endif

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress {
	if (!emailAddress) {
		return NO;
	}
	
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[^\\s@]+@[^\\s@]+\\s*$" options:NSRegularExpressionCaseInsensitive error:&error];
	if (!regex) {
		ATLogError(@"Unable to build email regular expression: %@", error);
		return NO;
	}
	NSUInteger count = [regex numberOfMatchesInString:emailAddress options:NSMatchingAnchored range:NSMakeRange(0, [emailAddress length])];
	BOOL isValid = (count > 0);
	
	return isValid;
}
@end


@implementation ATUtilities (Private)
+ (void)setupDateFormatters {
	@synchronized(self) {
		if (dateFormatter == nil) {
			dateFormatter = [[NSDateFormatter alloc] init];
			NSLocale *enUSLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
			NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			[dateFormatter setLocale:enUSLocale];
			[dateFormatter setCalendar:calendar];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		}
	}
}

@end

extern CGRect ATCGRectOfEvenSize(CGRect inRect) {
	CGRect result = CGRectMake(floor(inRect.origin.x), floor(inRect.origin.y), ceil(inRect.size.width), ceil(inRect.size.height));
	
	if (fmod(result.size.width, 2.0) != 0.0) {
		result.size.width += 1.0;
	}
	if (fmod(result.size.height, 2.0) != 0.0) {
		result.size.height += 1.0;
	}
	
	return result;
}

CGSize ATThumbnailSizeOfMaxSize(CGSize imageSize, CGSize maxSize) {
	CGFloat ratio = MIN(maxSize.width/imageSize.width, maxSize.height/imageSize.height);
	if (ratio < 1.0) {
		return CGSizeMake(floor(ratio * imageSize.width), floor(ratio * imageSize.height));
	} else {
		return imageSize;
	}
}

CGRect ATThumbnailCropRectForThumbnailSize(CGSize imageSize, CGSize thumbnailSize) {
	CGFloat cropRatio = thumbnailSize.width/thumbnailSize.height;
	CGFloat sizeRatio = imageSize.width/imageSize.height;
	
	if (cropRatio < sizeRatio) {
		// Shrink width. eg. 100:100 < 1600:1200
		CGFloat croppedWidth = imageSize.width * (1.0/sizeRatio);
		CGFloat originX = floor((imageSize.width - croppedWidth)/2.0);
		
		return CGRectMake(originX, 0, croppedWidth, imageSize.height);
	} else if (cropRatio > sizeRatio) {
		// Shrink height. eg. 100:100 > 1200:1600
		CGFloat croppedHeight = floor(imageSize.height * sizeRatio);
		CGFloat originY = floor((imageSize.height - croppedHeight)/2.0);
		
		return CGRectMake(0, originY, imageSize.width, croppedHeight);
	} else {
		return CGRectMake(0, 0, imageSize.width, imageSize.height);
	}
}
