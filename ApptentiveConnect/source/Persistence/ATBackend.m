//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATBackend.h"
#import "ATAppConfigurationUpdateTask.h"
#import "ATAutomatedMessage.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATContactStorage.h"
#import "ATData.h"
#import "ATDataManager.h"
#import "ATDeviceUpdater.h"
#import "ATAutomatedMessage.h"
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ATNavigationController.h"
#import "ApptentiveMetrics.h"
#import "ATReachability.h"
#import "ATStaticLibraryBootstrap.h"
#import "ATTaskQueue.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATMessageDisplayType.h"
#import "ATGetMessagesTask.h"
#import "ATMessageCenterMetrics.h"
#import "ATMessageSender.h"
#import "ATMessageTask.h"
#import "ATMessagePanelViewController.h"
#import "ATTextMessage.h"
#import "ATLog.h"
#import "ATPersonUpdater.h"
#import "ATEngagementBackend.h"
#import "ATMessagePanelNewUIViewController.h"

typedef NS_ENUM(NSInteger, ATBackendState){
	ATBackendStateStarting,
	ATBackendStateWaitingForDataProtectionUnlock,
	ATBackendStateReady
};

NSString *const ATBackendBecameReadyNotification = @"ATBackendBecameReadyNotification";

NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";
NSString *const ATLegacyUUIDPreferenceKey = @"ATLegacyUUIDPreferenceKey";
NSString *const ATInfoDistributionKey = @"ATInfoDistributionKey";
NSString *const ATInfoDistributionVersionKey = @"ATInfoDistributionVersionKey";

static NSURLCache *imageCache = nil;

@interface ATBackend ()
- (void)updateConfigurationIfNeeded;
@end

@interface ATBackend (Private)
- (void)setupDataManager;
- (void)setup;
- (void)startup;
- (void)continueStartupWithDataManagerSuccess;
- (void)continueStartupWithDataManagerFailure;
- (void)updateWorking;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)personDataChanged:(NSNotification *)notification;
- (void)deviceDataChanged:(NSNotification *)notification;
- (void)checkForMessages;
- (void)startMonitoringUnreadMessages;
- (void)checkForProperConfiguration;
@end

@interface ATBackend ()

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIViewController *presentingViewController;
#endif
@property (nonatomic, assign) BOOL working;
@property (nonatomic, strong) UIAlertView *messagePanelSentMessageAlert;
@property (nonatomic, strong) NSTimer *messageRetrievalTimer;
@property (nonatomic, assign) BOOL apiKeySet;
@property (nonatomic, copy) NSString *cachedDeviceUUID;
@property (nonatomic, assign) ATBackendState state;
@property (nonatomic, strong) UIViewController *presentedMessageCenterViewController;
@property (nonatomic, strong) ATMessagePanelViewController *currentMessagePanelController;
@property (nonatomic, strong) ATDataManager *dataManager;
@property (nonatomic, strong) ATConversationUpdater *conversationUpdater;
@property (nonatomic, strong) ATDeviceUpdater *deviceUpdater;
@property (nonatomic, strong) ATPersonUpdater *personUpdater;
@property (nonatomic, strong) NSFetchedResultsController *unreadCountController;
@property (nonatomic, assign) NSInteger previousUnreadCount;
@property (nonatomic, assign) BOOL shouldStopWorking;
@property (nonatomic, assign) BOOL networkAvailable;

@end

@implementation ATBackend
@synthesize supportDirectoryPath = _supportDirectoryPath;

+ (ATBackend *)sharedBackend {
	static ATBackend *sharedBackend = nil;
	@synchronized(self) {
		if (sharedBackend == nil) {
			sharedBackend = [[self alloc] init];
			[sharedBackend startup];
		}
	}
	return sharedBackend;
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	UIImage *result = nil;
	CGFloat scale = [[UIScreen mainScreen] scale];
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [UIImage imageWithContentsOfFile:imagePath];
	} else {
		result = [UIImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	NSImage *result = nil;
	CGFloat scale = 1.0;
	
	if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
		scale = (CGFloat)[[NSScreen mainScreen] backingScaleFactor];
	}
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	} else {
		result = [NSImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#endif

- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (void)dealloc {
	self.messagePanelSentMessageAlert.delegate = nil;
	[self.messageRetrievalTimer invalidate];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setApiKey:(NSString *)APIKey {
	if (_apiKey != APIKey) {
		_apiKey = APIKey;
		if (_apiKey == nil) {
			self.apiKeySet = NO;
		} else {
			self.apiKeySet = YES;
		}
		[self updateWorking];
	}
}

- (void)sendFeedback:(ATFeedback *)feedback {
	@autoreleasepool {
		if ([[NSThread currentThread] isMainThread]) {
			[self performSelectorInBackground:@selector(sendFeedback:) withObject:feedback];
			return;
		}
		if (feedback == self.currentFeedback) {
			self.currentFeedback = nil;
		}
		ATContactStorage *contact = [ATContactStorage sharedContactStorage];
		contact.name = feedback.name;
		contact.email = feedback.email;
		contact.phone = feedback.phone;
		[ATContactStorage releaseSharedContactStorage];
		contact = nil;
		
		ATFeedbackTask *task = [[ATFeedbackTask alloc] init];
		task.feedback = feedback;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		task = nil;
		
	}
}

- (void)sendAutomatedMessageWithTitle:(NSString *)title body:(NSString *)body {
	// See if there is already a message with this type.
	BOOL hidden = NO;
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(title = %@ AND body = %@)", title, body];
	NSArray *results = [ATData findEntityNamed:@"ATAutomatedMessage" withPredicate:fetchPredicate];
	if (results && [results count]) {
		hidden = YES;
	}
	
	ATAutomatedMessage *message = (ATAutomatedMessage *)[ATData newEntityNamed:@"ATAutomatedMessage"];
	[message setup];
	message.hidden = @(hidden);
	message.title = title;
	message.body = body;
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
	message.sentByUser = @YES;
	[message updateClientCreationTime];
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {
		ATLogError(@"Unable to send automated message with title: %@, body: %@, error: %@", title, body, error);
		message = nil;
		return;
	}
	
	// Give it a wee bit o' delay.
	NSString *pendingMessageID = [message pendingMessageID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		ATMessageTask *task = [[ATMessageTask alloc] init];
		task.pendingMessageID = pendingMessageID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[[ATTaskQueue sharedTaskQueue] start];
	});
	message = nil;
}

- (BOOL)sendTextMessageWithBody:(NSString *)body completion:(void (^)(NSString *pendingMessageID))completion {
	return [self sendTextMessageWithBody:body hiddenOnClient:NO completion:completion];
}

- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden completion:(void (^)(NSString *pendingMessageID))completion {
	[self updatePersonIfNeeded];
	ATTextMessage *message = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
	[message setup];
	message.body = body;
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
	message.sentByUser = @YES;
	message.hidden = @(hidden);
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (conversation) {
		ATMessageSender *sender = [ATMessageSender findSenderWithID:conversation.personID];
		if (sender) {
			message.sender = sender;
		}
	}
	
	if (!hidden) {
		[self attachCustomDataToMessage:message];
	}
	
	[message updateClientCreationTime];
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {
		ATLogError(@"Unable to send text message with body: %@, error: %@", body, error);
		message = nil;
		return NO;
	}
	if (completion) {
		completion(message.pendingMessageID);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidSendNotification object:@{ATMessageCenterMessageNonceKey:message.pendingMessageID}];
	
	// Give it a wee bit o' delay.
	NSString *pendingMessageID = [message pendingMessageID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		ATMessageTask *task = [[ATMessageTask alloc] init];
		task.pendingMessageID = pendingMessageID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[[ATTaskQueue sharedTaskQueue] start];
	});
	message = nil;
	return YES;
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image fromSource:(ATFeedbackImageSource)imageSource {
	return [self sendImageMessageWithImage:image hiddenOnClient:NO fromSource:imageSource];
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden fromSource:(ATFeedbackImageSource)imageSource {
	[self updatePersonIfNeeded];
	NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
	NSString *mimeType = @"image/jpeg";
	ATFIleAttachmentSource source = ATFileAttachmentSourceUnknown;
	switch (imageSource) {
		case ATFeedbackImageSourceCamera:
		case ATFeedbackImageSourcePhotoLibrary:
			source = ATFileAttachmentSourceCamera;
			break;
			/* for now we're going to assume camera…
			 source = ATFileAttachmentSourcePhotoLibrary;
			 break;
			 */
		case ATFeedbackImageSourceScreenshot:
			source = ATFileAttachmentSourceScreenshot;
			break;
		case ATFeedbackImageSourceProgrammatic:
			source = ATFIleAttachmentSourceProgrammatic;
			break;
	}
	
	return [self sendFileMessageWithFileData:imageData andMimeType:mimeType hiddenOnClient:hidden fromSource:source];
}


- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType fromSource:(ATFIleAttachmentSource)source {
	return [self sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:NO fromSource:source];
}

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden fromSource:(ATFIleAttachmentSource)source {
	[self updatePersonIfNeeded];
	ATFileMessage *fileMessage = (ATFileMessage *)[ATData newEntityNamed:@"ATFileMessage"];
	fileMessage.pendingState = @(ATPendingMessageStateSending);
	fileMessage.sentByUser = @YES;
	fileMessage.hidden = @(hidden);
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (conversation) {
		ATMessageSender *sender = [ATMessageSender findSenderWithID:conversation.personID];
		if (sender) {
			fileMessage.sender = sender;
		}
	}
	[fileMessage updateClientCreationTime];
	
	ATFileAttachment *fileAttachment = (ATFileAttachment *)[ATData newEntityNamed:@"ATFileAttachment"];
	[fileAttachment setFileData:fileData];
	[fileAttachment setMimeType:mimeType];
	[fileAttachment setSource:@(source)];
	fileMessage.fileAttachment = fileAttachment;
	
	[[[ATBackend sharedBackend] managedObjectContext] save:nil];
	
	// Give it a wee bit o' delay.
	NSString *pendingMessageID = [fileMessage pendingMessageID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		ATMessageTask *task = [[ATMessageTask alloc] init];
		task.pendingMessageID = pendingMessageID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[[ATTaskQueue sharedTaskQueue] start];
	});
	fileMessage = nil;
	fileAttachment = nil;
	return YES;
}

- (NSString *)supportDirectoryPath {
	if (!_supportDirectoryPath) {
		NSString *appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
		NSString *apptentiveDirectoryPath = [appSupportDirectoryPath stringByAppendingPathComponent:@"com.apptentive.feedback"];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *error = nil;
		
		if (![fm createDirectoryAtPath:apptentiveDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ATLogError(@"Failed to create support directory: %@", apptentiveDirectoryPath);
			ATLogError(@"Error was: %@", error);
			return nil;
		}
		
		if (![fm setAttributes:@{NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:apptentiveDirectoryPath error:&error]) {
			ATLogError(@"Failed to set file protection level: %@", apptentiveDirectoryPath);
			ATLogError(@"Error was: %@", error);
		}
	
		_supportDirectoryPath = apptentiveDirectoryPath;
	}
	
	return _supportDirectoryPath;
}

- (NSString *)attachmentDirectoryPath {
	NSString *supportPath = [self supportDirectoryPath];
	if (!supportPath) {
		return nil;
	}
	NSString *newPath = [supportPath stringByAppendingPathComponent:@"attachments"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ATLogError(@"Failed to create attachments directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)deviceUUID {
#if TARGET_OS_IPHONE
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *uuid = [defaults objectForKey:ATUUIDPreferenceKey];
		
		if (uuid && [uuid hasPrefix:@"ios:"]) {
			// Existing UUID is a legacy value. Back it up.
			[defaults setObject:uuid forKey:ATLegacyUUIDPreferenceKey];
		}
		
		UIDevice *device = [UIDevice currentDevice];
		if ([NSUUID class] && [device respondsToSelector:@selector(identifierForVendor)]) {
			NSString *vendorID = [[device identifierForVendor] UUIDString];
			if (vendorID && ![vendorID isEqualToString:uuid]) {
				uuid = vendorID;
				[defaults setObject:uuid forKey:ATUUIDPreferenceKey];
			}
		}
		if (!uuid) {
			// Fall back.
			CFUUIDRef uuidRef = CFUUIDCreate(NULL);
			CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
			
			uuid = [NSString stringWithFormat:@"ios:%@", (__bridge NSString *)uuidStringRef];
			
			CFRelease(uuidRef), uuidRef = NULL;
			CFRelease(uuidStringRef), uuidStringRef = NULL;
			[defaults setObject:uuid forKey:ATUUIDPreferenceKey];
			[defaults synchronize];
		}
		self.cachedDeviceUUID = uuid;
	});
	return self.cachedDeviceUUID;
#elif TARGET_OS_MAC
	static CFStringRef keyRef = CFSTR("apptentiveUUID");
	static CFStringRef appIDRef = CFSTR("com.apptentive.feedback");
	NSString *uuid = nil;
	uuid = (NSString *)CFPreferencesCopyAppValue(keyRef, appIDRef);
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [[NSString alloc] initWithFormat:@"osx:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
		
		CFPreferencesSetValue(keyRef, (CFStringRef)uuid, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize(appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	}
	return [uuid autorelease];
#endif
}

- (NSString *)appName {
	NSString *displayName = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppConfigurationAppDisplayNameKey];
	if (displayName) {
		return displayName;
	}
	
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

- (BOOL)isReady {
	return (self.state == ATBackendStateReady);
}

- (NSString *)cacheDirectoryPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	NSString *newPath = [path stringByAppendingPathComponent:@"com.apptentive"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ATLogError(@"Failed to create support directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)imageCachePath {
	NSString *cachePath = [self cacheDirectoryPath];
	if (!cachePath) {
		return nil;
	}
	NSString *imageCachePath = [cachePath stringByAppendingPathComponent:@"images.cache"];
	return imageCachePath;
}

- (NSURLCache *)imageCache {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageCachePath = [self imageCachePath];
		if (imageCachePath) {
			imageCache = [[NSURLCache alloc] initWithMemoryCapacity:1*1024*1024 diskCapacity:10*1024*1024 diskPath:imageCachePath];
		}
	});
	return imageCache;
}

#pragma mark Message Center
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController {
	[self presentMessageCenterFromViewController:viewController withCustomData:nil];
}

- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
	
	if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
		// Only present Message Center UI in Active state.
		return;
	}
	
	self.currentCustomData = customData;
	
	if (!viewController) {
		ATLogError(@"Attempting to present Apptentive Message Center from a nil View Controller.");
	}
	
	NSPredicate *notHidden = [NSPredicate predicateWithFormat:@"hidden != %@", @YES];
	NSUInteger messageCount = [ATData countEntityNamed:@"ATAbstractMessage" withPredicate:notHidden];
	if (messageCount == 0 || ![[ATConnect sharedConnection] messageCenterEnabled]) {
		NSString *title = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
		NSString *body = [NSString stringWithFormat:ATLocalizedString(@"Please let us know how to make %@ better for you!", @"Feedback screen body. Parameter is the app name."), [self appName]];
		NSString *placeholder = [ATConnect sharedConnection].customPlaceholderText ?: ATLocalizedString(@"How can we help? (required)", @"First feedback placeholder text.");
		
		[self presentIntroDialogFromViewController:viewController withTitle:title prompt:body placeholderText:placeholder];
		return;
	}
	
	if (self.presentedMessageCenterViewController != nil) {
		ATLogInfo(@"Apptentive message center controller already shown.");
		return;
	}
	ATMessageCenterBaseViewController *vc = nil;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		vc = [[ATMessageCenterV7ViewController alloc] init];
	} else {
		vc = [[ATMessageCenterViewController alloc] init];
	}
	vc.dismissalDelegate = self;
	ATNavigationController *nc = [[ATNavigationController alloc] initWithRootViewController:vc];
	nc.disablesAutomaticKeyboardDismissal = NO;
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[viewController presentViewController:nc animated:YES completion:^{}];
	self.presentedMessageCenterViewController = nc;
	vc = nil;
}

- (void)attachCustomDataToMessage:(ATAbstractMessage *)message {
	if (self.currentCustomData) {
		[message addCustomDataFromDictionary:self.currentCustomData];
		// Only attach custom data to the first message.
		self.currentCustomData = nil;
	}
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	self.currentCustomData = nil;
	
	if (self.currentMessagePanelController != nil) {
		[self.currentMessagePanelController dismissAnimated:animated completion:^{
			completion();
		}];
		return;
	}
	
	if (self.presentedMessageCenterViewController != nil) {
		UIViewController *vc = [self.presentedMessageCenterViewController presentingViewController];
		[vc dismissViewControllerAnimated:YES completion:^{
			completion();
		}];
		return;
	}
	
	if (completion) {
		// Call completion block even if we do nothing.
		completion();
	}
}

- (void)presentIntroDialogFromViewController:(UIViewController *)viewController withTitle:(NSString *)title prompt:(NSString *)prompt placeholderText:(NSString *)placeholder {
	@synchronized(self) {
		if (self.currentMessagePanelController) {
			ATLogInfo(@"Apptentive message panel controller already shown.");
			return;
		}
		
		ATMessagePanelViewController *vc;
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"]) {
			vc = [[ATMessagePanelNewUIViewController alloc] initWithDelegate:self];
		}
		else {
			vc = [[ATMessagePanelViewController alloc] initWithDelegate:self];
		}
		
		if (title) {
			vc.promptTitle = title;
		}
		if (prompt) {
			vc.promptText = prompt;
		}
		if (placeholder) {
			vc.customPlaceholderText = placeholder;
		}
		[vc setShowEmailAddressField:[[ATConnect sharedConnection] showEmailField]];
		[vc presentFromViewController:viewController animated:YES];
		self.currentMessagePanelController = vc;
		self.presentingViewController = viewController;
	}
}

- (void)presentIntroDialogFromViewController:(UIViewController *)viewController {
	[self presentIntroDialogFromViewController:viewController withTitle:nil prompt:nil placeholderText:nil];
}

#if TARGET_OS_IPHONE
#pragma mark ATMessagePanelDelegate
- (void)messagePanelDidCancel:(ATMessagePanelViewController *)messagePanel {
	if (self.currentMessagePanelController == messagePanel) {
		return;
	}
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didSendMessage:(NSString *)message withEmailAddress:(NSString *)emailAddress {
	if (self.currentMessagePanelController == messagePanel) {
		ATPersonInfo *person = nil;
		if ([ATPersonInfo personExists]) {
			person = [ATPersonInfo currentPerson];
		} else {
			person = [[ATPersonInfo alloc] init];
		}
		if (emailAddress && ![emailAddress isEqualToString:person.emailAddress]) {
			// Do not save empty string as person's email address
			if (emailAddress.length > 0) {
				person.emailAddress = emailAddress;
				person.needsUpdate = YES;
			}
			
			// Deleted email address from form, then submitted.
			if ([emailAddress isEqualToString:@""] && person.emailAddress) {
				person.emailAddress = @"";
				person.needsUpdate = YES;
			}
		}
		
		[person saveAsCurrentPerson];
		
		[self sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidSendNotification object:nil userInfo:@{ATMessageCenterMessageNonceKey: pendingMessageID}];
		}];
	}
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didDismissWithAction:(ATMessagePanelDismissAction)action {
	if (self.currentMessagePanelController) {
		self.currentMessagePanelController = nil;
		if (action == ATMessagePanelDidSendMessage) {
			if (!self.messagePanelSentMessageAlert) {
				
				NSString *alertTitle, *alertMessage, *cancelButtonTitle, *otherButtonTitle;
				if ([[ATConnect sharedConnection] messageCenterEnabled]) {
					alertTitle = ATLocalizedString(@"Thanks!", nil);
					alertMessage = ATLocalizedString(@"Your response has been saved in the Message Center, where you'll be able to view replies and send us other messages.", @"Message panel sent message confirmation dialog text");
					cancelButtonTitle = ATLocalizedString(@"Close", @"Close alert view title");
					otherButtonTitle = ATLocalizedString(@"View Messages", @"View messages button title");
				} else {
					alertTitle = ATLocalizedString(@"Thank you for your feedback!", @"Message panel sent message but will not show Message Center dialog.");
					alertMessage = nil;
					cancelButtonTitle = ATLocalizedString(@"Close", @"Close alert view title");
					otherButtonTitle = nil;
				}
				self.messagePanelSentMessageAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];
				[self.messagePanelSentMessageAlert show];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidShowNotification object:self userInfo:nil];
			}
		}
	}
}

- (NSString *)initialEmailAddressForMessagePanel {
	NSString *email = [ATConnect sharedConnection].initialUserEmailAddress;
	
	if ([ATPersonInfo personExists]) {
		email = [ATPersonInfo currentPerson].emailAddress;
	}
	
	return email;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.messagePanelSentMessageAlert) {
		if (buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouHitMessagesNotification object:self userInfo:nil];
			UIViewController *vc = [self presentingViewController];
			self.presentingViewController = nil;
			[self presentMessageCenterFromViewController:vc];
			vc = nil;
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidCloseNotification object:self userInfo:nil];
		}
		self.messagePanelSentMessageAlert.delegate = nil;
		self.messagePanelSentMessageAlert = nil;
	}
}
#endif

#pragma mark Accessors

- (void)setWorking:(BOOL)working {
	if (_working != working) {
		_working = working;
		if (_working) {
			[[ATTaskQueue sharedTaskQueue] start];
			
			[self updateConversationIfNeeded];
			[self updateConfigurationIfNeeded];
		} else {
			[[ATTaskQueue sharedTaskQueue] stop];
			[ATTaskQueue releaseSharedTaskQueue];
		}
	}
}


- (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
	return [self.dataManager managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [self.dataManager persistentStoreCoordinator];
}

#pragma mark -

- (BOOL)hideBranding {
	return [[NSUserDefaults standardUserDefaults] boolForKey:ATAppConfigurationHideBrandingKey];
}

- (void)updateConversationIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateConversationIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (!self.conversationUpdater && [ATConversationUpdater shouldUpdate]) {
		self.conversationUpdater = [[ATConversationUpdater alloc] initWithDelegate:self];
		[self.conversationUpdater createOrUpdateConversation];
	}
}

- (void)updateDeviceIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateDeviceIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	if (!self.deviceUpdater && [ATDeviceUpdater shouldUpdate]) {
		self.deviceUpdater = [[ATDeviceUpdater alloc] initWithDelegate:self];
		[self.deviceUpdater update];
	}
}

- (void)updatePersonIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updatePersonIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	if (!self.personUpdater && [ATPersonUpdater shouldUpdate]) {
		self.personUpdater = [[ATPersonUpdater alloc] initWithDelegate:self];
		[self.personUpdater update];
	}
}

- (BOOL)isUpdatingPerson {
	return self.personUpdater != nil;
}

- (void)updateConfigurationIfNeeded {
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	
	ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
	if (![queue hasTaskOfClass:[ATAppConfigurationUpdateTask class]]) {
		ATAppConfigurationUpdateTask *task = [[ATAppConfigurationUpdateTask alloc] init];
		[queue addTask:task];
		task = nil;
	}
}

#if TARGET_OS_IPHONE
#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (controller == self.unreadCountController) {
		id<NSFetchedResultsSectionInfo> sectionInfo = [[self.unreadCountController sections] objectAtIndex:0];
		NSUInteger unreadCount = [sectionInfo numberOfObjects];
		if (unreadCount != self.previousUnreadCount) {
			self.previousUnreadCount = unreadCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterUnreadCountChangedNotification object:nil userInfo:@{@"count":@(self.previousUnreadCount)}];
		}
	}
}
#endif

#pragma mark ATActivityFeedUpdaterDelegate
- (void)conversationUpdater:(ATConversationUpdater *)updater createdConversationSuccessfully:(BOOL)success {
	if (self.conversationUpdater == updater) {
		self.conversationUpdater = nil;
		if (!success) {
			// Retry after delay.
			[self performSelector:@selector(updateConversationIfNeeded) withObject:nil afterDelay:20];
		} else {
			// Queued tasks can probably start now.
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			[queue start];
			[self updateConfigurationIfNeeded];
			[self updateDeviceIfNeeded];
			[self updatePersonIfNeeded];
		}
	}
}

- (void)conversationUpdater:(ATConversationUpdater *)updater updatedConversationSuccessfully:(BOOL)success {
	if (self.conversationUpdater == updater) {
		self.conversationUpdater = nil;
	}
}

#pragma mark ATDeviceUpdaterDelegate
- (void)deviceUpdater:(ATDeviceUpdater *)aDeviceUpdater didFinish:(BOOL)success {
	if (self.deviceUpdater == aDeviceUpdater) {
		self.deviceUpdater = nil;
	}
}

#pragma mark ATPersonUpdaterDelegate
- (void)personUpdater:(ATPersonUpdater *)aPersonUpdater didFinish:(BOOL)success {
	if (self.personUpdater == aPersonUpdater) {
		self.personUpdater = nil;
		// Give task queue a bump if necessary.
		if (success && [self isReady] && !self.shouldStopWorking) {
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			[queue start];
		}
	}
}

#if TARGET_OS_IPHONE
- (void)messageCenterWillDismiss:(ATMessageCenterBaseViewController *)messageCenter {
	if (self.presentedMessageCenterViewController) {
		self.presentedMessageCenterViewController = nil;
	}
}
#endif

#pragma mark -

- (NSURL *)apptentivePrivacyPolicyURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/privacy"];
}

- (NSString *)distributionName {
	static NSString *cachedDistributionName = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		cachedDistributionName = (NSString *)[[ATConnect resourceBundle] objectForInfoDictionaryKey:ATInfoDistributionKey];
	});
	return cachedDistributionName;
}

- (NSString *)distributionVersion {
	static NSString *cachedDistributionVersion = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		cachedDistributionVersion = (NSString *)[[ATConnect resourceBundle] objectForInfoDictionaryKey:ATInfoDistributionVersionKey];
	});
	return cachedDistributionVersion;
}

- (NSUInteger)unreadMessageCount {
	return self.previousUnreadCount;
}

- (void)checkForMessagesAtForegroundRefreshInterval {
	NSNumber *refreshIntervalNumber = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
	int refreshInterval = 8;
	if (refreshIntervalNumber) {
		refreshInterval = [refreshIntervalNumber intValue];
		refreshInterval = MAX(4, refreshInterval);
	}
	
	[self checkForMessagesAtRefreshInterval:refreshInterval];
}

- (void)checkForMessagesAtBackgroundRefreshInterval {
	NSNumber *refreshIntervalNumber = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
	int refreshInterval = 60;
	if (refreshIntervalNumber) {
		refreshInterval = [refreshIntervalNumber intValue];
		refreshInterval = MAX(30, refreshInterval);
	}
	
	[self checkForMessagesAtRefreshInterval:refreshInterval];
}

- (void)checkForMessagesAtRefreshInterval:(NSTimeInterval)refreshInterval {
	@synchronized(self) {
		if (self.messageRetrievalTimer) {
			[self.messageRetrievalTimer invalidate];
			self.messageRetrievalTimer = nil;
		}
		
		self.messageRetrievalTimer = [NSTimer timerWithTimeInterval:refreshInterval target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES];
		NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
		[mainRunLoop addTimer:self.messageRetrievalTimer forMode:NSDefaultRunLoopMode];
	}
}

- (void)messageCenterEnteredForeground {
	@synchronized(self) {
		[self checkForMessages];
		
		[self checkForMessagesAtForegroundRefreshInterval];
	}
}

- (void)messageCenterLeftForeground {
	@synchronized(self) {
		[self checkForMessagesAtBackgroundRefreshInterval];
	}
}
@end

@implementation ATBackend (Private)
/* Methods which are safe to run when sharedBackend is still nil. */
- (void)setup {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(setup) withObject:nil waitUntilDone:YES];
		return;
	}
	[ATStaticLibraryBootstrap forceStaticLibrarySymbolUsage];
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForMessages) name:UIApplicationWillEnterForegroundNotification object:nil];
#elif TARGET_OS_MAC
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:NSApplicationWillTerminateNotification object:nil];
#endif
	
	[self checkForMessagesAtBackgroundRefreshInterval];
}

/* Methods which are not safe to run until sharedBackend is assigned. */
- (void)startup {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(startup) withObject:nil waitUntilDone:NO];
		return;
	}
	[self setupDataManager];
}

- (void)continueStartupWithDataManagerSuccess {
	self.state = ATBackendStateReady;
	[ApptentiveMetrics sharedMetrics];
	
	[ATMessageDisplayType setupSingletons];
	
	// One-shot actions at startup.
	[self performSelector:@selector(checkForProperConfiguration) withObject:nil afterDelay:1];
	[self performSelector:@selector(checkForEngagementManifest) withObject:nil afterDelay:3];
	[self performSelector:@selector(updateDeviceIfNeeded) withObject:nil afterDelay:7];
	[self performSelector:@selector(checkForMessages) withObject:nil afterDelay:8];
	[self performSelector:@selector(updatePersonIfNeeded) withObject:nil afterDelay:9];
	
	[ATReachability sharedReachability];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ATReachabilityStatusChanged object:nil];
	[self networkStatusChanged:nil];
	[self performSelector:@selector(startMonitoringUnreadMessages) withObject:nil afterDelay:0.2];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATBackendBecameReadyNotification object:nil];
	
	// Monitor changes to custom data.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(personDataChanged:) name:ATConnectCustomPersonDataChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDataChanged:) name:ATConnectCustomDeviceDataChangedNotification object:nil];
}

- (void)continueStartupWithDataManagerFailure {
	[self performSelector:@selector(checkForProperConfiguration) withObject:nil afterDelay:1];
}

- (void)updateWorking {
	if (self.shouldStopWorking) {
		// Probably going into the background or being terminated.
		self.working = NO;
	} else if (self.state != ATBackendStateReady) {
		// Backend isn't ready yet.
		self.working = NO;
	} else if (self.apiKeySet && self.networkAvailable && self.dataManager != nil && [self.dataManager persistentStoreCoordinator] != nil) {
		// API Key is set and the network and Core Data stack is up. Start working.
		self.working = YES;
	} else {
		// No API Key, no network, or no Core Data. Stop working.
		self.working = NO;
	}
}

#pragma mark Notification Handling
- (void)networkStatusChanged:(NSNotification *)notification {
	ATNetworkStatus status = [[ATReachability sharedReachability] currentNetworkStatus];
	if (status == ATNetworkNotReachable) {
		self.networkAvailable = NO;
	} else {
		self.networkAvailable = YES;
	}
	[self updateWorking];
}

- (void)stopWorking:(NSNotification *)notification {
	self.shouldStopWorking = YES;
	[self updateWorking];
}

- (void)startWorking:(NSNotification *)notification {
	self.shouldStopWorking = NO;
	[self updateWorking];
}

- (void)personDataChanged:(NSNotification *)notification {
	[self performSelector:@selector(updatePersonIfNeeded) withObject:nil afterDelay:1];
}

- (void)deviceDataChanged:(NSNotification *)notification {
	[self performSelector:@selector(updateDeviceIfNeeded) withObject:nil afterDelay:1];
}

- (void)checkForEngagementManifest {
	@autoreleasepool {
		if (![self isReady]) {
			return;
		}
		[[ATEngagementBackend sharedBackend] checkForEngagementManifest];
	}
}

- (void)checkForMessages {
	@autoreleasepool {
		@synchronized(self) {
			if (![self isReady] || self.shouldStopWorking) {
				return;
			}
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			if (![queue hasTaskOfClass:[ATGetMessagesTask class]]) {
				ATGetMessagesTask *task = [[ATGetMessagesTask alloc] init];
				[queue addTask:task];
				task = nil;
			}
		}
	}
}

- (void)setupDataManager {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(setupDataManager) withObject:nil waitUntilDone:YES];
		return;
	}
	ATLogInfo(@"Setting up data manager");
	
	if (![[UIApplication sharedApplication] isProtectedDataAvailable]) {
		self.state = ATBackendStateWaitingForDataProtectionUnlock;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDataManager) name:UIApplicationProtectedDataDidBecomeAvailable object:nil];
		return;
	} else if (self.state == ATBackendStateWaitingForDataProtectionUnlock) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationProtectedDataDidBecomeAvailable object:nil];
		self.state = ATBackendStateStarting;
	}
	
	self.dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[ATConnect resourceBundle] storagePath:[self supportDirectoryPath]];
	if (![self.dataManager setupAndVerify]) {
		ATLogError(@"Unable to setup and verify data manager.");
		[self continueStartupWithDataManagerFailure];
	} else if (![self.dataManager persistentStoreCoordinator]) {
		ATLogError(@"There was a problem setting up the persistent store coordinator!");
		[self continueStartupWithDataManagerFailure];
	} else {
		[self continueStartupWithDataManagerSuccess];
	}
}

- (void)startMonitoringUnreadMessages {
	@autoreleasepool {
#if TARGET_OS_IPHONE
		if (self.unreadCountController != nil) {
			ATLogError(@"startMonitoringUnreadMessages called more than once!");
			return;
		}
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:[self managedObjectContext]]];
		[request setFetchBatchSize:20];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		sortDescriptor = nil;
		
		NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"seenByUser == %@ AND sentByUser == %@", @(NO), @(NO)];
		request.predicate = unreadPredicate;
		
		NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-unread-messages-cache"];
		newController.delegate = self;
		self.unreadCountController = newController;
		
		NSError *error = nil;
		if (![self.unreadCountController performFetch:&error]) {
			ATLogError(@"got an error loading unread messages: %@", error);
			//!! handle me
		} else {
			[self controllerDidChangeContent:self.unreadCountController];
		}
		
		request = nil;
#endif
	}
}

- (void)checkForProperConfiguration {
	static BOOL checkedAlready = NO;
	if (checkedAlready) {
		// Don't display more than once.
		return;
	}
	checkedAlready = YES;
#if TARGET_IPHONE_SIMULATOR
	if ([ATConnect resourceBundle] == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Find Resources" message:@"Unable to find `ApptentiveResources.bundle`. Did you remember to add it to your target's Copy Bundle Resources build phase?" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	} else if (self.persistentStoreCoordinator == nil || self.managedObjectContext == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Setup Core Data" message:@"Unable to setup Core Data store. Did you link against Core Data? If so, something else may be wrong." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
#endif
}
@end
