//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogMonitor.h"
#import "ApptentiveUtilities.h"

static NSString * const KeyAccessToken = @"accessToken";
static NSString * const KeyEmailRecipients = @"emailRecipients";
static NSString * const KeyLogLevel = @"logLevel";

static NSString * const ConfigurationStorageFile = @"apptentive-log-monitor.cfg";

static ApptentiveLogMonitor * _sharedInstance;

@interface ApptentiveLogMonitorConfigration () <NSCoding>

@end

@implementation ApptentiveLogMonitorConfigration

- (instancetype)initWithAccessToken:(NSString *)accessToken {
	self = [super init];
	if (self) {
		_accessToken = accessToken;
		_emailRecipients = @[@"support@apptentive.com"];
		_logLevel = ApptentiveLogLevelVerbose;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_accessToken forKey:KeyAccessToken];
	[coder encodeObject:[_emailRecipients componentsJoinedByString:@","] forKey:KeyEmailRecipients];
	[coder encodeInt:(int)_logLevel forKey:KeyLogLevel];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) {
		_accessToken = [decoder decodeObjectForKey:KeyAccessToken];
		_emailRecipients = [[decoder decodeObjectForKey:KeyEmailRecipients] componentsSeparatedByString:@","];
		_logLevel = (ApptentiveLogLevel) [decoder decodeIntForKey:KeyLogLevel];
		_restored = YES;
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"accessToken=%@ logLevel=%@ recipients=%@ restored=%@", _accessToken, NSStringFromApptentiveLogLevel(_logLevel), [_emailRecipients componentsJoinedByString:@","], _restored ? @"YES" : @"NO"];
}

@end

@implementation ApptentiveLogMonitor

- (instancetype)initWithConfiguration:(ApptentiveLogMonitorConfigration *)configuration {
	self = [super init];
	if (self) {
		// FIXME: init instance
	}
	return self;
}

- (void)start {
	
}

+ (BOOL)tryInitialize {
	@try {
		NSString *storagePath = [self configurationStoragePath];
		ApptentiveLogMonitorConfigration *configuration = [self readConfigurationFromStoragePath:storagePath];
		if (configuration != nil) {
			ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Read log monitor configuration from persistent storage: %@", configuration);
		} else {
			configuration = [self readConfigurationFromClipboard];
			if (configuration != nil) {
				ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Read log monitor configuration from clipboard: %@", configuration);
				// FIXME: clear clipboard text
			}
		}
		
		if (configuration != nil) {
			[self writeConfiguration:configuration toStoragePath:storagePath];
			
			_sharedInstance = [[ApptentiveLogMonitor alloc] initWithConfiguration:configuration];
			[_sharedInstance start];
			return YES;
		}
	} @catch (NSException *e) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Exception while initializing log monitor: %@", e);
	}
	
	return NO;
}

+ (nullable ApptentiveLogMonitorConfigration *)readConfigurationFromStoragePath:(NSString *)path {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void)writeConfiguration:(ApptentiveLogMonitorConfigration *)configuration toStoragePath:(NSString *)path {
	[NSKeyedArchiver archiveRootObject:configuration toFile:path];
}

+ (nullable ApptentiveLogMonitorConfigration *)readConfigurationFromClipboard {
	return nil; // FIXME: read configuration from the clipboard
}

+ (NSString *)configurationStoragePath {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:ConfigurationStorageFile];
}

@end
