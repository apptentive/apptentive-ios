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
#import "ApptentiveArchiver.h"
#import "ApptentiveUnarchiver.h"
#import "UIWindow+Apptentive.h"

NSNotificationName const ApptentiveLogMonitorSessionDidStart = @"ApptentiveLogMonitorSessionDidStart";
NSNotificationName const ApptentiveLogMonitorSessionDidStop = @"ApptentiveLogMonitorSessionDidStop";

static NSString *const kSessionStorageFile = @"apptentive-log-monitor.cfg";
static NSString *const kManifestFileName = @"apptentive-manifest.txt";
static NSString *const kKeyEmailRecipients = @"emailRecipients";

extern NSString *ApptentiveLocalizedString(NSString *key, NSString *_Nullable comment);

@interface ApptentiveLogMonitorSession () <NSSecureCoding, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIWindow *presentationWindow;
@property (nonatomic, assign) ApptentiveLogLevel oldLogLevel;

@end

@implementation ApptentiveLogMonitorSession

+ (BOOL)supportsSecureCoding {
	return YES;
}

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
		_emailRecipients = [[decoder decodeObjectOfClass:[NSString class] forKey:kKeyEmailRecipients] componentsSeparatedByString:@","];
	}
	return self;
}

- (void)start {
	self.oldLogLevel = ApptentiveLogGetLevel();
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Overriding log level: %@", NSStringFromApptentiveLogLevel(ApptentiveLogLevelVerbose));
	ApptentiveLogSetLevel(ApptentiveLogLevelVerbose);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentationWindow == nil) {
			[self showReportUI];
		}
	});
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveLogMonitorSessionDidStart object:nil];
}

- (void)resume {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentationWindow == nil) {
			[self showReportUI];
		}
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
	self.presentationWindow = [UIWindow apptentive_windowWithRootViewController:[[UIViewController alloc] init]];
	
	// create alert controller with "Send", "Continue" and "Discard" actions
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ApptentiveLocalizedString(@"Apptentive", @"Apptentive") message:ApptentiveLocalizedString(@"Troubleshooting mode", @"Troubleshooting mode") preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Send Report", @"Send Report")
														style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction *_Nonnull action) {
		self.presentationWindow.hidden = YES;
		self.presentationWindow = nil;
		[self sendReportWithAttachedFiles:[ApptentiveLogMonitorSession listAttachments]];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Continue", @"Continue")
														style:UIAlertActionStyleCancel
													  handler:^(UIAlertAction *_Nonnull action) {
		self.presentationWindow.hidden = YES;
		self.presentationWindow = nil;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"Discard Report", @"Discard Report")
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction *_Nonnull action) {
		self.presentationWindow.hidden = YES;
		self.presentationWindow = nil;
		[self stop];
	}]];
	
	self.presentationWindow.hidden = NO; // don't use makeKeyAndVisible since we don't have any knowledge about the host app's UI
	[self.presentationWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Report

- (void)sendReportWithAttachedFiles:(NSArray<NSString *> *)files {
	// Present mail view controller/unavailable alert on screen in a separate window
	UIViewController *presentedViewController = nil;

	self.presentationWindow = [UIWindow apptentive_windowWithRootViewController:[[UIViewController alloc] init]];
	self.presentationWindow.hidden = NO;

	if ([MFMailComposeViewController canSendMail]) {
		// collecting system info
		NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];

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

		presentedViewController = mc;
	} else {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ApptentiveLocalizedString(@"Apptentive Log Monitor", @"Apptentive Log Monitor") message:ApptentiveLocalizedString(@"Unable to send email", @"Unable to send email") preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"OK", @"OK")
															style:UIAlertActionStyleCancel
														  handler:^(UIAlertAction *_Nonnull action) {
			self.presentationWindow.hidden = YES;
			self.presentationWindow = nil;
		}]];

		presentedViewController = alertController;
	}

	[self.presentationWindow.rootViewController presentViewController:presentedViewController animated:YES completion:nil];
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
	[controller dismissViewControllerAnimated:YES
								   completion:^{
									   [self stop];
									   self.presentationWindow.hidden = YES;
									   self.presentationWindow = nil;
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
	return filepath != nil ? [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveLogMonitorSession class] fromFile:filepath] : nil;
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
		[ApptentiveArchiver archiveRootObject:session toFile:filepath];
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
