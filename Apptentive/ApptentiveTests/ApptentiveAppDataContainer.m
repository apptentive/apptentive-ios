//
//  ApptentiveAppDataContainer.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppDataContainer.h"

static inline void throwException(NSString *format, ...) {
	va_list ap;
	va_start(ap, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);

	@throw [NSError errorWithDomain:@"ApptentiveErrorDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: message}];
}


@implementation ApptentiveAppDataContainer

+ (void)pushDataContainerWithName:(NSString *)name {
	NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"xcappdata"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
		throwException(@"App data doesn't exist: %@", name);
	}

	NSString *prefsPath = [bundlePath stringByAppendingString:@"/AppData/Library/Preferences/com.apptentive.ApptentiveDev.plist"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:prefsPath isDirectory:NULL]) {
		throwException(@"Prefs path doesn't exist: %@", prefsPath);
	}

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
	if (prefsPath == nil) {
		throwException(@"Prefs path doesn't exist: %@", prefsPath);
	}

	for (NSString *key in [[NSUserDefaults standardUserDefaults] dictionaryRepresentation].allKeys) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	}
	for (NSString *key in prefs.allKeys) {
		[[NSUserDefaults standardUserDefaults] setObject:prefs[key] forKey:key];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
