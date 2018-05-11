//
//  ApptentiveLogMonitorSession.m
//  Apptentive
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "ApptentiveLogMonitorSession.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveFileUtilities.h"
#import "ApptentiveJWT.h"
#import "ApptentiveSafeCollections.h"

NSNotificationName const ApptentiveLogMonitorSessionDidStart = @"ApptentiveLogMonitorSessionDidStart";
NSNotificationName const ApptentiveLogMonitorSessionDidStop = @"ApptentiveLogMonitorSessionDidStop";

static NSString *const kSessionStorageFile = @"apptentive-log-monitor.cfg";
static NSString *const kManifestFileName = @"apptentive-manifest.txt";
static NSString *const kKeyEmailRecipients = @"emailRecipients";

extern NSString *ApptentiveLocalizedString(NSString *key, NSString *_Nullable comment);

@interface ApptentiveLogMonitorSession () <NSCoding, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIWindow *mailComposeControllerWindow;
@property (nonatomic, assign) ApptentiveLogLevel oldLogLevel;

@end

@implementation ApptentiveLogMonitorSession

- (instancetype)init {
	self = [super init];
	if (self) {
		_emailRecipients = @[@"support@apptentive.com"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:[_emailRecipients componentsJoinedByString:@","] forKey:kKeyEmailRecipients];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) {
		_emailRecipients = [[decoder decodeObjectForKey:kKeyEmailRecipients] componentsSeparatedByString:@","];
	}
	return self;
}

- (void)start {
	self.oldLogLevel = ApptentiveLogGetLevel();
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Overriding log level: %@", NSStringFromApptentiveLogLevel(ApptentiveLogLevelVerbose));
	ApptentiveLogSetLevel(ApptentiveLogLevelVerbose);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self showReportUI];
	});
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveLogMonitorSessionDidStart object:nil];
}

- (void)resume {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self showReportUI];
	});
}

- (void)stop {
	ApptentiveLogSetLevel(self.oldLogLevel);
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveLogMonitorSessionDidStop object:nil];
}

#pragma mark -
#pragma mark User Interactions

- (void)showReportUI {
	// create a custom window to show UI on top of everything
	UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	// create alert controller with "Send", "Continue" and "Discard" actions
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ApptentiveLocalizedString(@"Apptentive", @"Apptentive") message:ApptentiveLocalizedString(@"Troubleshooting mode", @"Troubleshooting mode") preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Send Report", @"Send Report")
														style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction *_Nonnull action) {
														  window.hidden = YES;
														  [self sendReportWithAttachedFiles:[ApptentiveLogMonitorSession listAttachments]];
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Continue", @"Continue")
														style:UIAlertActionStyleCancel
													  handler:^(UIAlertAction *_Nonnull action) {
														  window.hidden = YES;
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Discard Report", @"Discard Report")
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
#pragma mark Report

- (void)sendReportWithAttachedFiles:(NSArray<NSString *> *)files {
	if (![MFMailComposeViewController canSendMail]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ApptentiveLocalizedString(@"Apptentive Log Monitor", @"Apptentive Log Monitor") message:ApptentiveLocalizedString(@"Unable to send email", @"Unable to send email") delegate:nil cancelButtonTitle:ApptentiveLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
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
									   [self stop];
									   self.mailComposeControllerWindow.hidden = YES;
									   self.mailComposeControllerWindow = nil;
								   }];
}

#pragma mark -
#pragma mark Helpers

+ (NSArray<NSString *> *)listAttachments {
	NSMutableArray<NSString *> *attachments = [NSMutableArray new];
	ApptentiveArrayAddObject(attachments, [self manifestFilePath]);
	NSArray<NSString *> *logFiles = ApptentiveListLogFiles();
	for (NSString *logFile in logFiles) {
		ApptentiveArrayAddObject(attachments, logFile);
	}
	return attachments;
}

+ (NSString *)manifestFilePath {
	return [ApptentiveUtilities cacheDirectoryPath:kManifestFileName];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"recipients=%@", [_emailRecipients componentsJoinedByString:@","]];
}

@end

@implementation ApptentiveLogMonitorSessionIO

+ (nullable ApptentiveLogMonitorSession *)readSessionFromPersistentStorage {
	NSString *filepath = [self sessionStoragePath];
	ApptentiveAssertNotNil(filepath, @"Session path is nil");
	return filepath != nil ? [NSKeyedUnarchiver unarchiveObjectWithFile:filepath] : nil;
}

+ (void)clearCurrentSession {
	NSString *filepath = [self sessionStoragePath];
	ApptentiveAssertNotNil(filepath, @"Session path is nil");
	[ApptentiveFileUtilities deleteFileAtPath:filepath];
}

+ (void)writeSessionToPersistentStorage:(ApptentiveLogMonitorSession *)session {
	ApptentiveAssertNotNil(session, @"Session is nil");
	NSString *filepath = [self sessionStoragePath];
	ApptentiveAssertNotNil(filepath, @"Session path is nil");
	if (filepath) {
		[NSKeyedArchiver archiveRootObject:session toFile:filepath];
	}
}

+ (nullable ApptentiveLogMonitorSession *)readSessionFromJWT:(NSString *)token {
	NSError *jwtError;
	ApptentiveJWT *jwt = [ApptentiveJWT JWTWithContentOfString:token error:&jwtError];
	if (jwtError != nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"JWT parsing error (%@)", jwtError);
		return nil;
	}
	
	ApptentiveLogMonitorSession *configuration = [[ApptentiveLogMonitorSession alloc] init];
	
	NSArray *emailRecepients = ApptentiveDictionaryGetArray(jwt.payload, @"recipients");
	if (emailRecepients != nil) {
		configuration.emailRecipients = emailRecepients;
	}
	
	return configuration;
}

+ (NSString *)sessionStoragePath {
	return [ApptentiveUtilities cacheDirectoryPath:kSessionStorageFile];
}

@end
