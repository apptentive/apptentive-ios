//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveLogMonitor.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveLogWriter.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveSafeCollections.h"

#import <MessageUI/MessageUI.h>

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

@interface ApptentiveLogMonitor () <MFMailComposeViewControllerDelegate>

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) ApptentiveLogLevel logLevel;
@property (nonatomic, readonly) NSArray *emailRecipients;
@property (nonatomic, readonly, getter=isSessionRestored) BOOL sessionRestored;
@property (nonatomic, readonly) ApptentiveLogWriter *logWriter;
@property (nonatomic, strong) UIWindow *mailComposeControllerWindow;

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

#pragma mark -
#pragma mark Life cycle

- (void)start {
	NSString *logFilePath = [self logFilePath];
	if (!_sessionRestored) {
		[ApptentiveUtilities deleteFileAtPath:logFilePath];
	}
	
	ApptentiveLogWriter *logWriter = [[ApptentiveLogWriter alloc] initWithPath:logFilePath];
	ApptentiveSetLoggerCallback(^(ApptentiveLogLevel level, NSString *message) {
		[logWriter appendMessage:message];
	});
	[logWriter start];
	
	_logWriter = logWriter;
	
	if (_sessionRestored) {
		// dispatch on the main thread to avoid UI-issues
		dispatch_async(dispatch_get_main_queue(), ^{
			[self showReportUI];
		});
	}
	
	[self registerNotifications];
}

- (void)stop {
	ApptentiveSetLoggerCallback(nil);
	[_logWriter stop];
	[ApptentiveLogMonitor clearConfiguration];
	
	[self unregisterNotifications];
}

#pragma mark -
#pragma mark Notifications

- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)unregisterNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification {
	[self showReportUI];
}

#pragma mark -
#pragma mark User Interactions

- (void)showReportUI {
	// create a custom window to show UI on top of everything
	UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	// create alert controller with "Send", "Continue" and "Discard" actions
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Apptentive" message:@"Log Monitor" preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Send Report" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		window.hidden = YES;
		__weak id weakSelf = self;
		_logWriter.finishCallback = ^(ApptentiveLogWriter *writer) {
			[weakSelf sendReportWithLogFile:writer.path];
		};
		[self stop];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		window.hidden = YES;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Discard Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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
				// save configuration
				[self writeConfiguration:configuration toStoragePath:storagePath];
				
				// clear pastboard text
				[[UIPasteboard generalPasteboard] setString:@""];
			}
		}
		
		if (configuration != nil) {
			_sharedInstance = [[ApptentiveLogMonitor alloc] initWithConfiguration:configuration];
			[_sharedInstance start];
			return YES;
		}
	} @catch (NSException *e) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Exception while initializing log monitor: %@", e);
	}
	
	return NO;
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

#pragma mark -
#pragma mark Report

- (void)sendReportWithLogFile:(NSString *)path {
	if (![MFMailComposeViewController canSendMail]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Apptentive Log Monitor" message:@"Unable to send email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		return;
	}
	
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	
	// collecting system info
	NSMutableString *messageBody = [NSMutableString new];
	[messageBody appendFormat:@"SDK: %@\n", kApptentiveVersionString];
	[messageBody appendFormat:@"Version: %@\n", [bundleInfo objectForKey:@"CFBundleShortVersionString"]];
	[messageBody appendFormat:@"Build: %@\n", [bundleInfo objectForKey:@"CFBundleVersion"]];
	[messageBody appendFormat:@"Device: %@\n", [ApptentiveUtilities deviceMachine]];
	[messageBody appendFormat:@"OS: %@\n", [UIDevice currentDevice].systemVersion];
	[messageBody appendFormat:@"Locale: %@", [NSLocale currentLocale].localeIdentifier];
	
	NSString *emailTitle = [NSString stringWithFormat:@"%@ device logs (iOS)", [NSBundle mainBundle].bundleIdentifier];
	
	MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
	mc.mailComposeDelegate = self;
	[mc setSubject:emailTitle];
	[mc setMessageBody:messageBody isHTML:NO];
	[mc setToRecipients:_emailRecipients];
	
	// Get the resource path and read the file using NSData
	NSString *filename = [path lastPathComponent];
	NSData *fileData = [NSData dataWithContentsOfFile:path];
	
	// Determine the MIME type
	NSString *mimeType = @"text/plain";
	
	// Add attachment
	[mc addAttachmentData:fileData mimeType:mimeType fileName:filename];
	
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
	[controller dismissViewControllerAnimated:YES completion:^{
		self.mailComposeControllerWindow.hidden = YES;
		self.mailComposeControllerWindow = nil;
	}];
}

#pragma mark -
#pragma mark Helpers

+ (NSString *)configurationStoragePath {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:ConfigurationStorageFile];
}

- (NSString *)logFilePath {
	NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	return [cacheDirectory stringByAppendingPathComponent:LogFileName];
}

@end
