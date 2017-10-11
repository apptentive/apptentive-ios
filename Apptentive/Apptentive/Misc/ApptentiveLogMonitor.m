//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogMonitor.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveLogWriter.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveSafeCollections.h"

static NSString * const KeyAccessToken = @"accessToken";
static NSString * const KeyEmailRecipients = @"emailRecipients";
static NSString * const KeyLogLevel = @"logLevel";

static NSString * const ConfigurationStorageFile = @"apptentive-log-monitor.cfg";
static NSString * const LogFileName = @"apptentive-log.txt";

static NSString * const DebugTextHeader = @"com.apptentive.debug";

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

@interface ApptentiveLogMonitor ()

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) ApptentiveLogLevel logLevel;
@property (nonatomic, readonly) NSArray *emailRecipients;
@property (nonatomic, readonly, getter=isSessionRestored) BOOL sessionRestored;
@property (nonatomic, readonly) ApptentiveLogWriter *logWriter;

@end

@implementation ApptentiveLogMonitor

- (instancetype)initWithConfiguration:(ApptentiveLogMonitorConfigration *)configuration {
	self = [super init];
	if (self) {
		_accessToken = configuration.accessToken;
		_logLevel = configuration.logLevel;
		_emailRecipients = configuration.emailRecipients;
		_sessionRestored = configuration.isRestored;
	}
	return self;
}

- (void)start {
	NSString *logFilePath = [self logFilePath];
	if (!_sessionRestored) {
		[ApptentiveUtilities deleteFileAtPath:logFilePath];
	}
	
	_logWriter = [[ApptentiveLogWriter alloc] initWithPath:logFilePath];
	[_logWriter start];
	
	// dispatch on the main thread to avoid UI-issues
	dispatch_async(dispatch_get_main_queue(), ^{
		// create a custom window to show UI on top of everything
		UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
		
		// create alert controller with "Send", "Continue" and "Discard" actions
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Apptentive" message:@"Log Monitor" preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Send Report" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			window.hidden = YES;
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			window.hidden = YES;
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Discard Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			window.hidden = YES;
		}]];
		
		window.rootViewController = [[UIViewController alloc] init];
		window.windowLevel = UIWindowLevelAlert + 1;
		window.hidden = NO; // don't use makeKeyAndVisible since we don't have any knowledge about the host app's UI
		[window.rootViewController presentViewController:alertController animated:YES completion:nil];
	});
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
				// clear pastboard text
				[[UIPasteboard generalPasteboard] setString:@""];
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
	NSString *text = [UIPasteboard generalPasteboard].string;
	
	// trim white spaces
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![text hasPrefix:DebugTextHeader]) {
		return nil;
	}
	
	NSString *payload = [text substringFromIndex:DebugTextHeader.length];
	
	NSError *error;
	id json = [ApptentiveJSONSerialization JSONObjectWithString:payload error:&error];
	if (json == nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Error while parsing json: %@", error);
		return nil;
	}
	
	if (![json isKindOfClass:[NSDictionary class]]) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unexpected json format: %@", payload);
		return nil;
	}
	
	NSString *accessToken = ApptentiveDictionaryGetString(json, @"accessToken");
	if (accessToken.length == 0) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unexpected json format (missing access token): %@", payload);
		return nil;
	}
	
	ApptentiveLogMonitorConfigration *configuration = [[ApptentiveLogMonitorConfigration alloc] initWithAccessToken:accessToken];
	
	NSString *logLevelStr = ApptentiveDictionaryGetString(json, @"level");
	ApptentiveLogLevel logLevel = ApptentiveLogLevelFromString(logLevelStr);
	if (logLevel != ApptentiveLogLevelUndefined) {
		configuration.logLevel = logLevel;
	}
	
	NSArray *emailRecepients = ApptentiveDictionaryGetArray(json, @"recipients");
	if (emailRecepients != nil) {
		configuration.emailRecipients = emailRecepients;
	}
	
	return configuration;
}

+ (NSString *)configurationStoragePath {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:ConfigurationStorageFile];
}

- (NSString *)logFilePath {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:LogFileName];
}

@end
