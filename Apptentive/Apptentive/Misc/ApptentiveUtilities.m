//
//  ApptentiveUtilities.m
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveUtilities.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

NS_ASSUME_NONNULL_BEGIN


UIViewController *topChildViewController(UIViewController *viewController) {
	if ([viewController isKindOfClass:[UINavigationController class]]) {
		return topChildViewController(((UINavigationController *)viewController).visibleViewController);
	} else if ([viewController isKindOfClass:[UITabBarController class]]) {
		return topChildViewController(((UITabBarController *)viewController).selectedViewController);
	} else if (viewController.presentedViewController) {
		return topChildViewController(viewController.presentedViewController);
	} else {
		return viewController;
	}
}


@implementation ApptentiveUtilities

+ (BOOL)fileExistsAtPath:(NSString *)path {
	return path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)deleteFileAtPath:(NSString *)path {
	return [self deleteFileAtPath:path error:NULL];
}

+ (BOOL)deleteFileAtPath:(NSString *)path error:(NSError **)error {
	return path != nil && [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (BOOL)deleteDirectoryAtPath:(NSString *)path error:(NSError **)error {
	return path != nil && [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (NSString *)applicationSupportPath {
	static NSString *_applicationSupportPath;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  _applicationSupportPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;

	  NSError *error;

	  if (![[NSFileManager defaultManager] createDirectoryAtPath:_applicationSupportPath withIntermediateDirectories:YES attributes:nil error:&error]) {
		  ApptentiveLogError(@"Failed to create Application Support directory: %@", _applicationSupportPath);
		  ApptentiveLogError(@"Error was: %@", error);
		  _applicationSupportPath = nil;
	  }


	  if (![[NSFileManager defaultManager] setAttributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication } ofItemAtPath:_applicationSupportPath error:&error]) {
		  ApptentiveLogError(@"Failed to set file protection level: %@", _applicationSupportPath);
		  ApptentiveLogError(@"Error was: %@", error);
	  }
	});

	return _applicationSupportPath;
}


+ (NSBundle *)resourceBundle {
	NSBundle *bundleForClass = [NSBundle bundleForClass:[self class]];
	NSString *resourceBundlePath = [bundleForClass pathForResource:@"ApptentiveResources" ofType:@"bundle"];

	// Resources may sit alongside this class in a framework or may be nested in resource bundle.
	return resourceBundlePath ? [NSBundle bundleWithPath:resourceBundlePath] : bundleForClass;
}

+ (UIStoryboard *)storyboard {
	return [UIStoryboard storyboardWithName:@"Apptentive" bundle:[self resourceBundle]];
}

+ (UIImage *)imageNamed:(NSString *)name {
	return [UIImage imageNamed:name inBundle:[self resourceBundle] compatibleWithTraitCollection:nil];
}

+ (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
}

+ (nullable NSString *)appName {
	NSString *displayName = nil;

	NSArray *appNameKeys = [NSArray arrayWithObjects:@"CFBundleDisplayName", (NSString *)kCFBundleNameKey, nil];
	NSMutableArray *infoDictionaries = [NSMutableArray array];
	if ([[NSBundle mainBundle] localizedInfoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] localizedInfoDictionary]];
	}
	if ([[NSBundle mainBundle] infoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] infoDictionary]];
	}
	for (NSDictionary *infoDictionary in infoDictionaries) {
		if (displayName != nil) {
			break;
		}
		for (NSString *appNameKey in appNameKeys) {
			displayName = [infoDictionary objectForKey:appNameKey];
			if (displayName != nil) {
				break;
			}
		}
	}
	return displayName;
}

+ (nullable UIViewController *)rootViewControllerForCurrentWindow {
	UIWindow *window = nil;
	for (UIWindow *tmpWindow in [[UIApplication sharedApplication] windows]) {
		if ([[tmpWindow screen] isEqual:[UIScreen mainScreen]] && [tmpWindow isKeyWindow]) {
			window = tmpWindow;
			break;
		}
	}

	if (window) {
		UIViewController *vc = window.rootViewController;

		return vc.presentedViewController ?: vc;
	} else {
		return nil;
	}
}

+ (UIViewController *)topViewController {
	return topChildViewController([UIApplication sharedApplication].delegate.window.rootViewController);
}

+ (nullable UIImage *)appIcon {
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
	  iconFile = maxImage;
	});
	return iconFile;
}

+ (NSString *)stringByEscapingForPredicate:(NSString *)string {
	return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
	static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	NSMutableString *result = [NSMutableString stringWithString:@""];
	for (NSUInteger i = 0; i < length; i++) {
		[result appendFormat:@"%c", [letters characterAtIndex:arc4random() % [letters length]]];
	}
	return result;
}

+ (NSString *)stringRepresentationOfDate:(NSDate *)aDate {
	static NSDateFormatter *dateFormatter = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  dateFormatter = [[NSDateFormatter alloc] init];
	  NSLocale *enUSLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	  [dateFormatter setLocale:enUSLocale];
	  [dateFormatter setCalendar:calendar];
	  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	});

	NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
	NSString *result = nil;
	@synchronized(self) { // to avoid calendars stepping on themselves
		dateFormatter.timeZone = timeZone;
		NSString *dateString = [dateFormatter stringFromDate:aDate];

		NSInteger timeZoneOffset = [timeZone secondsFromGMT];
		NSString *sign = (timeZoneOffset >= 0) ? @"+" : @"-";
		NSInteger hoursOffset = fabs(floor(timeZoneOffset / 60 / 60));
		NSInteger minutesOffset = abs((int)floor(timeZoneOffset / 60) % 60);
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
			f = nil;
		}
	}
	return result;
}

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b {
	NSArray *leftComponents = [a componentsSeparatedByString:@"."];
	NSArray *rightComponents = [b componentsSeparatedByString:@"."];
	NSUInteger maxComponents = MAX(leftComponents.count, rightComponents.count);

	NSComparisonResult comparisonResult = NSOrderedSame;
	for (NSUInteger i = 0; i < maxComponents; i++) {
		NSInteger leftComponent = 0;
		if (i < leftComponents.count) {
			leftComponent = [leftComponents[i] integerValue];
		}
		NSInteger rightComponent = 0;
		if (i < rightComponents.count) {
			rightComponent = [rightComponents[i] integerValue];
		}
		if (leftComponent == rightComponent) {
			continue;
		} else if (leftComponent > rightComponent) {
			comparisonResult = NSOrderedDescending;
			break;
		} else if (leftComponent < rightComponent) {
			comparisonResult = NSOrderedAscending;
			break;
		}
	}
	return comparisonResult;
}

+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedDescending);
}

+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedAscending);
}

+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedSame);
}

// Returns a dictionary consisting of:
//
// 1. Any key-value pairs that appear in new but not old
// 2. The keys that appear in old but not new with the values set to [NSNull null]
// 3. Any keys whose values have changed (with the new value)
//
// Nested dictionaries (e.g. custom_data) are sent in their entirety
// if they have changed (in order to match what the server is expecting).
+ (NSDictionary *)diffDictionary:(NSDictionary *) new againstDictionary:(NSDictionary *)old {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSArray *newKeys = [new.allKeys sortedArrayUsingSelector:@selector(compare:)];
	NSArray *oldKeys = [old.allKeys sortedArrayUsingSelector:@selector(compare:)];
	NSUInteger i = 0, j = 0;

	while (i < [newKeys count] || j < [oldKeys count]) {
		NSComparisonResult comp = NSOrderedSame;
		NSString *newKey;
		NSString *oldKey;

		if (i < [newKeys count] && j < [oldKeys count]) {
			newKey = newKeys[i];
			oldKey = oldKeys[j];
			comp = [newKey compare:oldKey];
		}
		if (i >= [newKeys count]) {
			oldKey = oldKeys[j];
			newKey = nil;
			comp = NSOrderedDescending;
		} else if (j >= [oldKeys count]) {
			newKey = newKeys[i];
			oldKey = nil;
			comp = NSOrderedAscending;
		}

		if (comp == NSOrderedSame) {
			// Same key, value may have changed
			NSString *key = newKey;
			if (key) {
				id newValue = new[key];
				id oldValue = old[key];

				if ([newValue isEqual:@""] && ![oldValue isEqual:@""]) {
					// Treat new empty strings as null
					result[key] = [NSNull null];
				} else if ([newValue isKindOfClass:[NSArray class]] && [oldValue isKindOfClass:[NSArray class]]) {
					if (![[newValue sortedArrayUsingSelector:@selector(compare:)] isEqualToArray:[oldValue sortedArrayUsingSelector:@selector(compare:)]]) {
						result[key] = newValue;
					}
				} else if (![newValue isEqual:oldValue]) {
					result[key] = newValue;
				}

				i++;
				j++;
			}
		} else if (comp == NSOrderedAscending) {
			// New key appeared
			result[newKey] = new[newKey];
			i++;
		} else if (comp == NSOrderedDescending) {
			// Old key disappeared
			result[oldKey] = [NSNull null];
			j++;
		}
	}

	return result;
}

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress {
	if (!emailAddress) {
		return NO;
	}

	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[^\\s@]+@[^\\s@]+\\s*$" options:NSRegularExpressionCaseInsensitive error:&error];
	if (!regex) {
		ApptentiveLogError(@"Unable to build email regular expression: %@", error);
		return NO;
	}
	NSUInteger count = [regex numberOfMatchesInString:emailAddress options:NSMatchingAnchored range:NSMakeRange(0, [emailAddress length])];
	BOOL isValid = (count > 0);

	return isValid;
}

+ (nullable NSData *)secureRandomDataOfLength:(NSUInteger)numberOfBytes {
	NSMutableData *randomData = [[NSMutableData alloc] initWithLength:numberOfBytes];

	int result = SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, randomData.mutableBytes);
	ApptentiveAssertTrue(result == 0, @"Unable to generate random data");

	return (result == 0) ? randomData : nil;
}

+ (NSString *)stringByPaddingBase64:(NSString *)base64String {
	NSUInteger lengthRoundedUpToNextMultipleOfFour = ceil(base64String.length / 4.0) * 4;

	return [base64String stringByPaddingToLength:lengthRoundedUpToNextMultipleOfFour withString:@"=" startingAtIndex:0];
}

+ (NSString *)formatAsTableRows:(NSArray<NSArray *> *)rows {
	NSMutableArray *columnSizes = [[NSMutableArray alloc] initWithCapacity:rows[0].count];
	for (int i = 0; i < rows[0].count; ++i) {
		[columnSizes addObject:@0];
	}

	for (NSArray *row in rows) {
		for (int i = 0; i < row.count; ++i) {
			columnSizes[i] = [NSNumber numberWithInteger:MAX([columnSizes[i] intValue], [row[i] description].length)];
		}
	}

	NSMutableString *line = [NSMutableString new];
	int totalSize = 0;
	for (int i = 0; i < columnSizes.count; ++i) {
		totalSize += [columnSizes[i] intValue];
	}
	totalSize += columnSizes.count > 0 ? (columnSizes.count - 1) * @" | ".length : 0;
	while (totalSize-- > 0) {
		[line appendString:@"-"];
	}

	NSMutableString *result = [[NSMutableString alloc] initWithString:line];

	for (NSArray *row in rows) {
		[result appendString:@"\n"];

		for (int i = 0; i < row.count; ++i) {
			if (i > 0) {
				[result appendString:@" | "];
			}
			[result appendString:[[row[i] description] stringByPaddingToLength:[columnSizes[i] intValue] withString:@" " startingAtIndex:0]];
		}
	}
	[result appendString:@"\n"];
	[result appendString:line];

	return result;
}

+ (NSString *)deviceMachine {
	struct utsname systemInfo;
	uname(&systemInfo);

	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end

NS_ASSUME_NONNULL_END
