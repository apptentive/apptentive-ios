//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveJWT.h"
#import "ApptentiveLogMonitor.h"
#import "ApptentiveLogWriter.h"
#import "ApptentiveSafeCollections.h"
#import "ApptentiveUtilities.h"

#import <MessageUI/MessageUI.h>

// These constants are defined in Apptentive-Private.h but the compiler is "unhappy" if
// this file is imported here (TODO: figure it out)
extern NSNotificationName _Nonnull const ApptentiveManifestRawDataDidReceiveNotification;
extern NSString *_Nonnull const ApptentiveManifestRawDataKey;

static NSString *const KeyEmailRecipients = @"emailRecipients";
static NSString *const KeyLogLevel = @"logLevel";

static NSString *const ConfigurationStorageFile = @"apptentive-log-monitor.cfg";
static NSString *const LogFileName = @"apptentive-log.txt";
static NSString *const ManifestFileName = @"apptentive-manifest.txt";

static NSString *const DebugTextHeader = @"com.apptentive.debug:";

static ApptentiveLogMonitor *_sharedInstance;


@interface ApptentiveLogMonitorConfigration () <NSCoding>

@end


@implementation ApptentiveLogMonitorConfigration

- (instancetype)init {
	self = [super init];
	if (self) {
		_emailRecipients = @[@"support@apptentive.com"];
		_logLevel = ApptentiveLogLevelVerbose;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:[_emailRecipients componentsJoinedByString:@","] forKey:KeyEmailRecipients];
	[coder encodeInt:(int)_logLevel forKey:KeyLogLevel];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) {
		_emailRecipients = [[decoder decodeObjectForKey:KeyEmailRecipients] componentsSeparatedByString:@","];
		_logLevel = (ApptentiveLogLevel)[decoder decodeIntForKey:KeyLogLevel];
		_restored = YES;
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"logLevel=%@ recipients=%@ restored=%@", NSStringFromApptentiveLogLevel(_logLevel), [_emailRecipients componentsJoinedByString:@","], _restored ? @"YES" : @"NO"];
}

@end


@interface ApptentiveLogMonitor () <MFMailComposeViewControllerDelegate>

@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) ApptentiveLogLevel logLevel;
@property (nonatomic, readonly) ApptentiveLogLevel originalLogLevel;
@property (nonatomic, readonly) NSArray *emailRecipients;
@property (nonatomic, readonly, getter=isSessionRestored) BOOL sessionRestored;
@property (nonatomic, readonly) ApptentiveLogWriter *logWriter;
@property (nonatomic, strong) UIWindow *mailComposeControllerWindow;

@end


@implementation ApptentiveLogMonitor

- (instancetype)initWithBaseURL:(NSURL *)baseURL configuration:(ApptentiveLogMonitorConfigration *)configuration {
	self = [super init];
	if (self) {
		_baseURL = baseURL;
		_originalLogLevel = ApptentiveLogGetLevel();
		_logLevel = configuration.logLevel;
		_emailRecipients = configuration.emailRecipients;
		_sessionRestored = configuration.isRestored;
	}
	return self;
}

#pragma mark -
#pragma mark Life cycle

- (void)start {
	ApptentiveLogSetLevel(_logLevel);
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Override log level %@ -> %@", NSStringFromApptentiveLogLevel(_originalLogLevel), NSStringFromApptentiveLogLevel(_logLevel));

	NSString *logFilePath = [ApptentiveLogMonitor logFilePath];
	if (!_sessionRestored) {
		[ApptentiveUtilities deleteFileAtPath:logFilePath];
	}

	ApptentiveLogWriter *logWriter = [[ApptentiveLogWriter alloc] initWithPath:logFilePath];
	ApptentiveSetLoggerCallback(^(ApptentiveLogLevel level, NSString *message) {
	  [logWriter appendMessage:message];
	});
	[logWriter start];

	_logWriter = logWriter;

	// dispatch on the main thread to avoid UI-issues
	dispatch_async(dispatch_get_main_queue(), ^{
	  [self showReportUI];
	});

	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Troubleshooting mode enabled");
}

- (void)resume {
	[self showReportUI];
}

- (void)stop {
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Troubleshooting mode disabled");

	// restore the original log level
	ApptentiveLogSetLevel(_originalLogLevel);

	// remove log callbacks
	ApptentiveSetLoggerCallback(nil);

	// stop writting logs
	[_logWriter stop];

	// delete store configuration
	[ApptentiveLogMonitor clearConfiguration];
}

#pragma mark -
#pragma mark User Interactions

- (void)showReportUI {
	// create a custom window to show UI on top of everything
	UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

	// create alert controller with "Send", "Continue" and "Discard" actions
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Apptentive" message:@"Troubleshooting mode" preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Send Report"
														style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction *_Nonnull action) {
														window.hidden = YES;
														__weak id weakSelf = self;
														_logWriter.finishCallback = ^(ApptentiveLogWriter *writer) {
														  dispatch_async(dispatch_get_main_queue(), ^{
															[weakSelf sendReportWithAttachedFiles:@[writer.path, [ApptentiveLogMonitor manifestFilePath]]];
														  });
														};
														[self stop];
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Continue"
														style:UIAlertActionStyleCancel
													  handler:^(UIAlertAction *_Nonnull action) {
														window.hidden = YES;
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Discard Report"
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction *_Nonnull action) {
														window.hidden = YES;
														[self stop];
													  }]];

	window.rootViewController = [[UIViewController alloc] init];
	window.windowLevel = UIWindowLevelAlert + 1;
	window.hidden = NO; // don't use makeKeyAndVisible since we don't have any knowledge about the host app's UI
	[window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Static initialization

+ (BOOL)tryInitializeWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature {
	if (baseURL == nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: base URL is nil");
		return NO;
	}

	if (appKey.length == 0) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: app key is nil or empty");
		return NO;
	}

	if (appSignature.length == 0) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: app signature is nil or empty");
		return NO;
	}

	// Store raw manifest data each time the update is received
	NSString *manifestPath = [ApptentiveLogMonitor manifestFilePath];
	[[NSNotificationCenter defaultCenter] addObserverForName:ApptentiveManifestRawDataDidReceiveNotification
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification *_Nonnull note) {
													NSData *data = note.userInfo[ApptentiveManifestRawDataKey];
													ApptentiveAssertNotNil(data, @"Missing manifest data");
													[data writeToFile:manifestPath atomically:YES];
												  }];

	@try {
		NSString *storagePath = [self configurationStoragePath];
		ApptentiveLogMonitorConfigration *configuration = [self readConfigurationFromStoragePath:storagePath];
		if (configuration != nil) {
			ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Read log monitor configuration from persistent storage: %@", configuration);
		} else {
			NSString *accessToken = [self readAccessTokenFromClipboard];
			if (![self syncVerifyAccessToken:accessToken baseURL:baseURL appKey:appKey signature:appSignature]) {
				return NO;
			}

			configuration = [self readConfigurationFromToken:accessToken];
			if (configuration != nil) {
				ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Read log monitor configuration from clipboard: %@", configuration);
				// save configuration
				[self writeConfiguration:configuration toStoragePath:storagePath];

				// clear pastboard text
				[[UIPasteboard generalPasteboard] setString:@""];
			}
		}

		if (configuration != nil) {
			_sharedInstance = [[ApptentiveLogMonitor alloc] initWithBaseURL:baseURL configuration:configuration];
			[_sharedInstance start];
			return YES;
		}
	} @catch (NSException *e) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Exception while initializing log monitor: %@", e);
	}

	return NO;
}

+ (instancetype)sharedInstance {
	return _sharedInstance;
}

#pragma mark -
#pragma mark Access Token

+ (nullable NSString *)readAccessTokenFromClipboard {
	NSString *text = [UIPasteboard generalPasteboard].string;

	// remove white spaces
	text = [text stringByReplacingOccurrencesOfString:@"\\s" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, text.length)];

	if (![text hasPrefix:DebugTextHeader]) {
		return nil;
	}
	
	// clear the token from the clipboard
	[UIPasteboard generalPasteboard].string = @"";

	return [text substringFromIndex:DebugTextHeader.length];
}

+ (BOOL)syncVerifyAccessToken:(NSString *)accessToken baseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature {
	if (accessToken.length == 0) {
		return NO;
	}

	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Starting access token verification: %@", accessToken);

	NSDate *startDate = [NSDate new];
	NSData *body = [ApptentiveJSONSerialization dataWithJSONObject:@{ @"debug_token": accessToken } options:0 error:nil];

	NSDictionary *headers = @{
		@"X-API-Version": kApptentiveAPIVersionString,
		@"APPTENTIVE-KEY": appKey,
		@"APPTENTIVE-SIGNATURE": appSignature,
		@"Content-Type": @"application/json",
		@"Accept": @"application/json",
		@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (iOS)", kApptentiveVersionString]
	};

	NSURL *URL = [NSURL URLWithString:@"/debug_token/verify" relativeToURL:baseURL];
	NSDictionary *json = [self loadJsonFromURL:URL body:body headers:headers];
	NSTimeInterval duration = -[startDate timeIntervalSinceNow];

	if (json == nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Access token verification failed: invalid server response (took %g sec)", duration);

		return NO;
	}

	BOOL valid = ApptentiveDictionaryGetBool(json, @"valid");
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Access token is %@ (took %g sec)", valid ? @"valid" : @"invalid", duration);

	return valid;
}

+ (NSDictionary *)loadJsonFromURL:(NSURL *)URL body:(NSData *)body headers:(NSDictionary *)headers {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	for (NSString *key in headers) {
		[request setValue:headers[key] forHTTPHeaderField:key];
	}
	request.HTTPBody = body;
	request.HTTPMethod = @"POST";

	NSURLResponse *response;
	NSError *requestError;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
#pragma clang diagnostic pop

	if (requestError != nil) {
		ApptentiveLogError(@"Unable to load json from URL: %@", requestError);
		return nil;
	}

	NSError *jsonError;
	id object = [ApptentiveJSONSerialization JSONObjectWithData:data error:&jsonError];
	if (jsonError != nil) {
		ApptentiveLogError(@"Unable to parse json from URL: %@", requestError);
		return nil;
	}

	if (![object isKindOfClass:[NSDictionary class]]) {
		ApptentiveLogError(@"Unexpected json object: %@", object);
		return nil;
	}

	return object;
}

#pragma mark -
#pragma mark Configuration

+ (nullable ApptentiveLogMonitorConfigration *)readConfigurationFromStoragePath:(NSString *)path {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void)clearConfiguration {
	NSString *filepath = [self configurationStoragePath];
	[ApptentiveUtilities deleteFileAtPath:filepath];
}

+ (void)writeConfiguration:(ApptentiveLogMonitorConfigration *)configuration toStoragePath:(NSString *)path {
	[NSKeyedArchiver archiveRootObject:configuration toFile:path];
}

+ (nullable ApptentiveLogMonitorConfigration *)readConfigurationFromToken:(NSString *)token {
	NSError *jwtError;
	ApptentiveJWT *jwt = [ApptentiveJWT JWTWithContentOfString:token error:&jwtError];
	if (jwtError != nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"JWT parsing error: %@", jwtError);
		return nil;
	}

	ApptentiveLogMonitorConfigration *configuration = [[ApptentiveLogMonitorConfigration alloc] init];

	NSString *logLevelStr = ApptentiveDictionaryGetString(jwt.payload, @"level");
	ApptentiveLogLevel logLevel = ApptentiveLogLevelFromString(logLevelStr);
	if (logLevel != ApptentiveLogLevelUndefined) {
		configuration.logLevel = logLevel;
	}

	NSArray *emailRecepients = ApptentiveDictionaryGetArray(jwt.payload, @"recipients");
	if (emailRecepients != nil) {
		configuration.emailRecipients = emailRecepients;
	}

	return configuration;
}

#pragma mark -
#pragma mark Report

- (void)sendReportWithAttachedFiles:(NSArray<NSString *> *)files {
	if (![MFMailComposeViewController canSendMail]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Apptentive Log Monitor" message:@"Unable to send email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
#pragma clang diagnostic pop

		return;
	}

	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];

	// collecting system info
	NSMutableString *messageBody = [NSMutableString new];
	[messageBody appendString:@"This email may contain sensitive content.\n Please review before sending.\n\n"];
	[messageBody appendFormat:@"App Bundle Identifier: %@\n", [NSBundle mainBundle].bundleIdentifier];
	[messageBody appendFormat:@"App Version: %@\n", [bundleInfo objectForKey:@"CFBundleShortVersionString"]];
	[messageBody appendFormat:@"App Build: %@\n", [bundleInfo objectForKey:@"CFBundleVersion"]];
	[messageBody appendFormat:@"Apptentive SDK: %@\n", kApptentiveVersionString];
	[messageBody appendFormat:@"Device Model: %@\n", [ApptentiveUtilities deviceMachine]];
	[messageBody appendFormat:@"iOS Version: %@\n", [UIDevice currentDevice].systemVersion];
	[messageBody appendFormat:@"Locale: %@", [NSLocale currentLocale].localeIdentifier];

	NSString *emailTitle = [NSString stringWithFormat:@"%@ (iOS)", [NSBundle mainBundle].infoDictionary[@"CFBundleName"]];

	MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
	mc.mailComposeDelegate = self;
	[mc setSubject:emailTitle];
	[mc setMessageBody:messageBody isHTML:NO];
	[mc setToRecipients:_emailRecipients];

	// Get the resource path and read the file using NSData
	for (NSString *path in files) {
		NSString *filename = [path lastPathComponent];
		NSData *fileData = [NSData dataWithContentsOfFile:path];
		if (fileData.length == 0) {
			ApptentiveLogError(ApptentiveLogTagMonitor, @"Attachment file does not exist or empty: %@", path);
			continue;
		}

		// Add attachment
		[mc addAttachmentData:fileData mimeType:@"text/plain" fileName:filename];
	}

	// Present mail view controller on screen in a separate window
	UIViewController *rootController = [UIViewController new];

	self.mailComposeControllerWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.mailComposeControllerWindow.windowLevel = UIWindowLevelAlert + 1;
	self.mailComposeControllerWindow.rootViewController = rootController;
	self.mailComposeControllerWindow.hidden = NO;

	[rootController presentViewController:mc animated:YES completion:nil];
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
	[controller dismissViewControllerAnimated:YES
								   completion:^{
									 self.mailComposeControllerWindow.hidden = YES;
									 self.mailComposeControllerWindow = nil;
								   }];
}

#pragma mark -
#pragma mark Helpers

+ (NSString *)configurationStoragePath {
	return [self cacheDirectoryPath:ConfigurationStorageFile];
}

+ (NSString *)logFilePath {
	return [self cacheDirectoryPath:LogFileName];
}

+ (NSString *)manifestFilePath {
	return [self cacheDirectoryPath:ManifestFileName];
}

+ (NSString *)cacheDirectoryPath:(NSString *)path {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:path];
}

@end
