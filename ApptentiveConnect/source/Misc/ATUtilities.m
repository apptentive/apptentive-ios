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

#define KINDA_EQUALS(a, b) (fabs(a - b) < 0.1)
#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

@implementation ATUtilities

#if TARGET_OS_IPHONE
// From QA1703:
// http://developer.apple.com/library/ios/#qa/qa1703/_index.html
// with changes to account for the application frame.
+ (UIImage*)imageByTakingScreenshot {
	// Create a graphics context with the target size
	// On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
	// On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	CGSize imageSize = applicationFrame.size;
	if (NULL != UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
	} else {
		UIGraphicsBeginImageContext(imageSize);
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Iterate over every window from back to front
	for (UIWindow *window in [[UIApplication sharedApplication] windows])  {
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
	CGImageAlphaInfo alphaInfo = kCGImageAlphaNone;
	size_t samplesPerPixel, bytesPerRow;
	CGFloat newHeight, newWidth;
	CGRect newRect;
	CGContextRef bitmapContext = nil;
	CGImageRef newRef = nil;
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	imageRef = [image CGImage];
	alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	samplesPerPixel = CGImageGetBitsPerPixel(imageRef)/CGImageGetBitsPerComponent(imageRef);
	if (alphaInfo == kCGImageAlphaNone) {
		samplesPerPixel++;
	}
	
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
	
	// 16-byte aligned, Quartz book p. 353
	bytesPerRow = ((size_t)(samplesPerPixel * newWidth) + 15) & ~15;
	
	CGImageAlphaInfo newAlphaInfo;
	if (alphaInfo == kCGImageAlphaNone) {
		newAlphaInfo = kCGImageAlphaNoneSkipLast;
	} else {
		newAlphaInfo = kCGImageAlphaPremultipliedFirst;
	}
	
	bitmapContext = CGBitmapContextCreate(NULL, newWidth, newHeight, CGImageGetBitsPerComponent(imageRef), bytesPerRow, CGImageGetColorSpace(imageRef), newAlphaInfo);
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
#elif TARGET_OS_MAC
+ (NSString *)currentMachineName {
	char modelBuffer[256];
	size_t sz = sizeof(modelBuffer);
	NSString *result = @"Unknown";
	if (0 == sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0)) {
		modelBuffer[sizeof(modelBuffer) - 1] = 0;
		result = [NSString stringWithUTF8String:modelBuffer];
	}
	return result;
}

+ (NSString *)currentSystemName {
	NSProcessInfo *info = [NSProcessInfo processInfo];
	NSString *osName = [info operatingSystemName];
	
	if ([osName isEqualToString:@"NSMACHOperatingSystem"]) {
		osName = @"Mac OS X";
	}
	
	return osName;
}

+ (NSString *)currentSystemVersion {
	NSProcessInfo *info = [NSProcessInfo processInfo];
	return [info operatingSystemVersionString];
}

+ (NSData *)pngRepresentationOfImage:(NSImage *)image {
	CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:nil];
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
	NSData *result = [imageRep representationUsingType:NSPNGFileType properties:nil];
	[imageRep release];
	return result;
}
#endif

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string {
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)@"%:/?#[]@!$&'()*+,;=", kCFStringEncodingUTF8);
	return [NSMakeCollectable(result) autorelease];
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
	static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	NSMutableString *result = [NSMutableString stringWithString:@""];
	for (NSUInteger i = 0; i < length; i++) {
		[result appendFormat:@"%c", [letters characterAtIndex:rand()%[letters length]]];
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
	static NSDateFormatter *dateFormatter = nil;
	static NSDateFormatter *timeZoneFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		timeZoneFormatter = [[NSDateFormatter alloc] init];
		[timeZoneFormatter setDateFormat:@"Z"];
	}
	NSString *result = nil;
	NSString *dateString = [dateFormatter stringFromDate:aDate];
	NSString *timeZoneString = [timeZoneFormatter stringFromDate:aDate];
	
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
	return result;
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
