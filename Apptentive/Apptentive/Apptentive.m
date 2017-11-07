//
//  Apptentive.m
//  Apptentive
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveBannerViewController.h"
#import "ApptentiveUnreadMessagesBadgeView.h"
#import "ApptentiveAboutViewController.h"
#import "ApptentiveStyleSheet.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveLogMonitor.h"

NS_ASSUME_NONNULL_BEGIN

NSNotificationName const ApptentiveMessageCenterUnreadCountChangedNotification = @"ApptentiveMessageCenterUnreadCountChangedNotification";

NSNotificationName const ApptentiveAppRatingFlowUserAgreedToRateAppNotification = @"ApptentiveAppRatingFlowUserAgreedToRateAppNotification";

NSNotificationName const ApptentiveSurveyShownNotification = @"ApptentiveSurveyShownNotification";
NSNotificationName const ApptentiveSurveySentNotification = @"ApptentiveSurveySentNotification";

NSNotificationName const ApptentiveCustomPersonDataChangedNotification = @"ApptentiveCustomPersonDataChangedNotification";
NSNotificationName const ApptentiveCustomDeviceDataChangedNotification = @"ApptentiveCustomDeviceDataChangedNotification";
NSNotificationName const ApptentiveInteractionsDidUpdateNotification = @"ApptentiveInteractionsDidUpdateNotification";
NSNotificationName const ApptentiveInteractionsShouldDismissNotification = @"ApptentiveInteractionsShouldDismissNotification";
NSNotificationName const ApptentiveConversationCreatedNotification = @"ApptentiveConversationCreatedNotification";
NSNotificationName const ApptentiveManifestRawDataDidReceiveNotification = @"ApptentiveManifestRawDataDidReceiveNotification";

NSString *const ApptentiveSurveyIDKey = @"ApptentiveSurveyIDKey";
NSString *const ApptentiveInteractionsShouldDismissAnimatedKey = @"ApptentiveInteractionsShouldDismissAnimatedKey";

NSString *const ApptentiveCustomDeviceDataPreferenceKey = @"ApptentiveCustomDeviceDataPreferenceKey";
NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";
NSString *const ApptentiveManifestRawDataKey = @"ApptentiveManifestRawDataKey";

NSString *const ApptentiveErrorDomain = @"com.apptentive";

static Apptentive *_sharedInstance;


@implementation ApptentiveConfiguration

+ (nullable instancetype)configurationWithApptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature {
	return [[self alloc] initWithApptentiveKey:apptentiveKey apptentiveSignature:apptentiveSignature];
}

- (nullable instancetype)initWithApptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature {
	self = [super init];
	if (self) {
		if (apptentiveKey.length == 0) {
			ApptentiveLogError(@"Can't create Apptentive configuration: key is nil or empty");
			return nil;
		}

		if (apptentiveSignature.length == 0) {
			ApptentiveLogError(@"Can't create Apptentive configuration: signature is nil or empty");
			return nil;
		}

		_apptentiveKey = [apptentiveKey copy];
		_apptentiveSignature = [apptentiveSignature copy];
		_baseURL = [NSURL URLWithString:@"https://api.apptentive.com/"];
		_logLevel = ApptentiveLogLevelInfo;
	}
	return self;
}

@end


@interface Apptentive () <ApptentiveBannerViewControllerDelegate>

@property (nonatomic, readonly) ApptentiveMessageManager *messageManager;

@end


@implementation Apptentive

@synthesize style = _style;

+ (instancetype)sharedConnection {
	if (_sharedInstance == nil) {
		ApptentiveLogWarning(@"Apptentive instance is not initialized. Make sure you've registered it with your app key and signature");
	}
	return _sharedInstance;
}

+ (instancetype)shared {
	return [self sharedConnection];
}

- (id)initWithConfiguration:(ApptentiveConfiguration *)configuration {
	self = [super init];

	if (self) {
		// it's important to set the log level first and the initialize log monitor
		// otherwise the log monitor configuration would be overwritten by
		// the SDK configuration
		ApptentiveLogSetLevel(configuration.logLevel);
		
		[ApptentiveLogMonitor tryInitializeWithBaseURL:configuration.baseURL appKey:configuration.apptentiveKey signature:configuration.apptentiveSignature];
		
		_operationQueue = [[NSOperationQueue alloc] init];
		_operationQueue.maxConcurrentOperationCount = 1;
		_operationQueue.name = @"Apptentive Operation Queue";

		_style = [[ApptentiveStyleSheet alloc] init];
		_apptentiveKey = configuration.apptentiveKey;
		_apptentiveSignature = configuration.apptentiveSignature;
		_baseURL = configuration.baseURL;
		_appID = configuration.appID;
		_backend = [[ApptentiveBackend alloc] initWithApptentiveKey:_apptentiveKey
														  signature:_apptentiveSignature
															baseURL:_baseURL
														storagePath:@"com.apptentive.feedback"
													 operationQueue:_operationQueue];

		if (configuration.distributionName && configuration.distributionVersion) {
			[ApptentiveSDK setDistributionName:configuration.distributionName];
			[ApptentiveSDK setDistributionVersion:[[ApptentiveVersion alloc] initWithString:configuration.distributionVersion]];
		}
		
		[self registerNotifications];

		ApptentiveLogInfo(@"Apptentive SDK Version %@", [ApptentiveSDK SDKVersion].versionString);
	}
	return self;
}

+ (void)registerWithConfiguration:(ApptentiveConfiguration *)configuration {
	if (_sharedInstance != nil) {
		ApptentiveLogWarning(@"Apptentive instance is already initialized");
		return;
	}
	@try {
		_sharedInstance = [[Apptentive alloc] initWithConfiguration:configuration];
	} @catch (NSException *e) {
		ApptentiveLogCrit(@"Exception while initializing Apptentive instance: %@", e);
	}
}

- (id<ApptentiveStyle>)styleSheet {
	[self setDidOverrideStyles];

	return _style;
}

- (void)setStyleSheet:(id<ApptentiveStyle>)style {
	_style = style;

	[self setDidOverrideStyles];
}

- (void)setDidOverrideStyles {
	if (!self.didAccessStyleSheet) {
		_didAccessStyleSheet = YES;

		[self.operationQueue addOperationWithBlock:^{
			if (self.backend.conversationManager.activeConversation) {
				[self.backend.conversationManager.activeConversation didOverrideStyles];
			}
		}];
	}
}

- (nullable NSString *)personName {
	return self.backend.conversationManager.activeConversation.person.name;
}

- (void)setPersonName:(nullable NSString *)personName {
	[self.operationQueue addOperationWithBlock:^{
		self.backend.conversationManager.activeConversation.person.name = personName;
		[self.backend schedulePersonUpdate];
	}];
}

- (nullable NSString *)personEmailAddress {
	return self.backend.conversationManager.activeConversation.person.emailAddress;
}

- (void)setPersonEmailAddress:(nullable NSString *)personEmailAddress {
	[self.operationQueue addOperationWithBlock:^{
		self.backend.conversationManager.activeConversation.person.emailAddress = personEmailAddress;
		[self.backend schedulePersonUpdate];
	}];
}

- (void)sendAttachmentText:(NSString *)text {
	[self.operationQueue addOperationWithBlock:^{
		if (self.backend.conversationManager.activeConversation == nil) {
			ApptentiveLogError(@"Attempting to send message with no active conversation.");
			return;
		}

		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:text attachments:nil automated:NO customData:nil];
		ApptentiveAssertNotNil(message, @"Message is nil");

		if (message != nil) {
            if (self.messageManager) {
                [self.messageManager enqueueMessageForSending:message];
            } else {
                ApptentiveLogError(@"Unable to send attachment text: message manager is not initialized");
            }
		}
	}];
}

- (void)sendAttachmentImage:(UIImage *)image {
	[self.operationQueue addOperationWithBlock:^{
		if (self.backend.conversationManager.activeConversation == nil) {
			ApptentiveLogError(@"Attempting to send message with no active conversation.");
			return;
		}

		if (image == nil) {
			ApptentiveLogError(@"Unable to send image attachment: image is nil");
			return;
		}

		NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
		if (imageData == nil) {
			ApptentiveLogError(@"Unable to send image attachment: image data is invalid");
			return;
		}

		if (self.backend.conversationManager.messageManager == nil) {
			ApptentiveLogError(@"Unable to send attachment file: message manager is not initialized");
			return;
		}

		ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithData:imageData contentType:@"image/jpeg" name:nil attachmentDirectoryPath:self.backend.conversationManager.messageManager.attachmentDirectoryPath];
		ApptentiveAssertNotNil(attachment, @"Attachment is nil");
		if (attachment != nil) {
			ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:nil attachments:@[attachment] automated:NO customData:nil];
			ApptentiveAssertNotNil(message, @"Message is nil");

			if (message != nil) {
                if (self.messageManager) {
                    [self.messageManager enqueueMessageForSending:message];
                } else {
                    ApptentiveLogError(@"Unable to send attachment image: message manager is not initialized");
                }
			}
		}
	}];
}

- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType {
	[self.operationQueue addOperationWithBlock:^{
		if (self.backend.conversationManager.activeConversation == nil) {
			ApptentiveLogError(@"Attempting to send message with no active conversation.");
			return;
		}

		if (fileData == nil) {
			ApptentiveLogError(@"Unable to send attachment file: file data is nil");
			return;
		}

		if (mimeType.length == 0) {
			ApptentiveLogError(@"Unable to send attachment file: mime-type is nil or empty");
			return;
		}

		if (self.backend.conversationManager.messageManager == nil) {
			ApptentiveLogError(@"Unable to send attachment file: message manager is not initialized");
			return;
		}

		ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithData:fileData contentType:mimeType name:nil attachmentDirectoryPath:self.backend.conversationManager.messageManager.attachmentDirectoryPath];
		ApptentiveAssertNotNil(attachment, @"Attachment is nil");

		if (attachment != nil) {
			ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:nil attachments:@[attachment] automated:NO customData:nil];

			ApptentiveAssertNotNil(message, @"Message is nil");
            if (message != nil) {
                if (self.messageManager) {
                    [self.messageManager enqueueMessageForSending:message];
                } else {
                    ApptentiveLogError(@"Unable to send attachment file: message manager is not initialized");
                }
            }
		}
	}];
}

- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.device addCustomString:string withKey:key];
		[self.backend scheduleDeviceUpdate];
	}];
}

- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.device addCustomNumber:number withKey:key];
		[self.backend scheduleDeviceUpdate];
	}];
}

- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.device addCustomBool:boolValue withKey:key];
		[self.backend scheduleDeviceUpdate];
	}];
}

- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.person addCustomString:string withKey:key];
		[self.backend schedulePersonUpdate];
	}];
}

- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.person addCustomNumber:number withKey:key];
		[self.backend schedulePersonUpdate];
	}];
}

- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.person addCustomBool:boolValue withKey:key];
		[self.backend schedulePersonUpdate];
	}];
}

+ (NSDictionary *)versionObjectWithVersion:(NSString *)version {
	return @{ @"_type": @"version",
		@"version": version ?: [NSNull null],
	};
}

+ (NSDictionary *)timestampObjectWithNumber:(NSNumber *)seconds {
	return @{ @"_type": @"datetime",
		@"sec": seconds,
	};
}

+ (NSDictionary *)timestampObjectWithDate:(NSDate *)date {
	return [self timestampObjectWithNumber:@([date timeIntervalSince1970])];
}

- (void)addCustomData:(NSObject *)object withKey:(NSString *)key toCustomDataDictionary:(NSMutableDictionary *)customData {
	BOOL simpleType = ([object isKindOfClass:[NSString class]] ||
		[object isKindOfClass:[NSNumber class]] ||
		[object isKindOfClass:[NSNull class]]);

	BOOL complexType = NO;
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSString *type = ((NSDictionary *)object)[@"_type"];
		if (type) {
			complexType = (type != nil);
		}
	}

	if (simpleType || complexType) {
		ApptentiveDictionarySetKeyValue(customData, key, object);
	} else {
		ApptentiveLogError(@"Apptentive custom data must be of type NSString, NSNumber, or NSNull, or a 'complex type' NSDictionary created by one of the constructors in Apptentive.h");
	}
}

- (void)removeCustomPersonDataWithKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.person removeCustomValueWithKey:key];
		[self.backend schedulePersonUpdate];
	}];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager.activeConversation.device removeCustomValueWithKey:key];
		[self.backend scheduleDeviceUpdate];
	}];
}

- (void)openAppStore {
	if (!self.appID) {
		ApptentiveLogError(@"Cannot open App Store because `[Apptentive sharedConnection].appID` is not set to your app's iTunes App ID.");
		return;
	}

	[self.backend engageApptentiveAppEvent:@"open_app_store_manually"];

	ApptentiveInteraction *appStoreInteraction = [[ApptentiveInteraction alloc] init];
	appStoreInteraction.type = @"AppStoreRating";
	appStoreInteraction.priority = 1;
	appStoreInteraction.version = @"1.0.0";
	appStoreInteraction.identifier = @"OpenAppStore";
	appStoreInteraction.configuration = @{ @"store_id": self.appID,
		@"method": @"app_store" };

	[self.backend presentInteraction:appStoreInteraction fromViewController:nil];
}

- (NSDictionary *)integrationConfiguration {
	ApptentiveAssertOperationQueue(self.operationQueue);
	return self.backend.conversationManager.activeConversation.device.integrationConfiguration;
}

- (void)setPushNotificationIntegration:(ApptentivePushProvider)pushProvider withDeviceToken:(NSData *)deviceToken {
	const unsigned *tokenBytes = [deviceToken bytes];
	NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
								ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
								ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
								ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

	[self.operationQueue addOperationWithBlock:^{
		ApptentiveDevice *device = self.backend.conversationManager.activeConversation.device;

		NSMutableDictionary *integrationConfiguration = [device.integrationConfiguration mutableCopy] ?: [NSMutableDictionary dictionary];

		[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderApptentive]];
		[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderUrbanAirship]];
		[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderAmazonSNS]];
		[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderParse]];

		ApptentiveDictionarySetKeyValue(integrationConfiguration, [self integrationKeyForPushProvider:pushProvider], @{ @"token": token });

		ApptentiveDevice.integrationConfiguration = integrationConfiguration;

		device.integrationConfiguration = integrationConfiguration;

		[self.backend scheduleDeviceUpdate];
	}];
}

- (NSString *)integrationKeyForPushProvider:(ApptentivePushProvider)pushProvider {
	switch (pushProvider) {
		case ApptentivePushProviderApptentive:
			return @"apptentive_push";
		case ApptentivePushProviderUrbanAirship:
			return @"urban_airship";
		case ApptentivePushProviderAmazonSNS:
			return @"aws_sns";
		case ApptentivePushProviderParse:
			return @"parse";
		default:
			return @"UNKNOWN_PUSH_PROVIDER";
	}
}

- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration {
	[self.operationQueue addOperationWithBlock:^{
		NSMutableDictionary *integrationConfiguration = [self.backend.conversationManager.activeConversation.device.integrationConfiguration mutableCopy];
		ApptentiveDictionarySetKeyValue(integrationConfiguration, integration, configuration);
		self.backend.conversationManager.activeConversation.device.integrationConfiguration = integrationConfiguration;
		[self.backend scheduleDeviceUpdate];
	}];
}

- (void)removeIntegration:(NSString *)integration {
	[self.operationQueue addOperationWithBlock:^{
		NSMutableDictionary *integrationConfiguration = [self.backend.conversationManager.activeConversation.device.integrationConfiguration mutableCopy];
		[integrationConfiguration removeObjectForKey:integration];
		self.backend.conversationManager.activeConversation.device.integrationConfiguration = integrationConfiguration;
		[self.backend scheduleDeviceUpdate];
	}];
}

- (BOOL)canShowInteractionForEvent:(NSString *)event {
	return [self.backend canShowInteractionForLocalEvent:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(nullable UIViewController *)viewController {
	return [self engage:event withCustomData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData fromViewController:(nullable UIViewController *)viewController {
	return [self engage:event withCustomData:customData withExtendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData withExtendedData:(nullable NSArray *)extendedData fromViewController:(nullable UIViewController *)viewController {
	@try {
		return [self.backend engageLocalEvent:event userInfo:nil customData:customData extendedData:extendedData fromViewController:viewController];
	} @catch (NSException *e) {
		ApptentiveLogCrit(@"Exception while engaging event: %@", event);
		return NO;
	}
}

+ (NSDictionary *)extendedDataDate:(NSDate *)date {
	NSDictionary *time = @{ @"time": @{@"version": @1,
		@"timestamp": @([date timeIntervalSince1970])}
	};
	return time;
}

+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude {
	// Coordinates sent to server in order (longitude, latitude)
	NSDictionary *location = @{ @"location": @{@"version": @1,
		@"coordinates": @[@(longitude), @(latitude)]}
	};

	return location;
}


+ (NSDictionary *)extendedDataCommerceWithTransactionID:(nullable NSString *)transactionID
											affiliation:(nullable NSString *)affiliation
												revenue:(nullable NSNumber *)revenue
											   shipping:(nullable NSNumber *)shipping
													tax:(nullable NSNumber *)tax
											   currency:(nullable NSString *)currency
										  commerceItems:(nullable NSArray *)commerceItems {
	NSMutableDictionary *commerce = [NSMutableDictionary dictionary];
	commerce[@"version"] = @1;

	if (transactionID) {
		commerce[@"id"] = transactionID;
	}

	if (affiliation) {
		commerce[@"affiliation"] = affiliation;
	}

	if (revenue != nil) {
		commerce[@"revenue"] = revenue;
	}

	if (shipping != nil) {
		commerce[@"shipping"] = shipping;
	}

	if (tax != nil) {
		commerce[@"tax"] = tax;
	}

	if (currency) {
		commerce[@"currency"] = currency;
	}

	if (commerceItems) {
		commerce[@"items"] = commerceItems;
	}

	return @{ @"commerce": commerce };
}

+ (NSDictionary *)extendedDataCommerceItemWithItemID:(nullable NSString *)itemID
												name:(nullable NSString *)name
											category:(nullable NSString *)category
											   price:(nullable NSNumber *)price
											quantity:(nullable NSNumber *)quantity
											currency:(nullable NSString *)currency {
	NSMutableDictionary *commerceItem = [NSMutableDictionary dictionary];
	commerceItem[@"version"] = @1;

	if (itemID) {
		commerceItem[@"id"] = itemID;
	}

	if (name) {
		commerceItem[@"name"] = name;
	}

	if (category) {
		commerceItem[@"category"] = category;
	}

	if (price != nil) {
		commerceItem[@"price"] = price;
	}

	if (quantity != nil) {
		commerceItem[@"quantity"] = quantity;
	}

	if (currency) {
		commerceItem[@"currency"] = currency;
	}

	return commerceItem;
}

- (BOOL)canShowMessageCenter {
	NSString *messageCenterCodePoint = [[ApptentiveInteraction apptentiveAppInteraction] codePointForEvent:ApptentiveEngagementMessageCenterEvent];
	return [self.backend canShowInteractionForCodePoint:messageCenterCodePoint];
}

- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController {
	return [self.backend presentMessageCenterFromViewController:viewController];
}

- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData {
	NSMutableDictionary *allowedCustomMessageData = [NSMutableDictionary dictionary];

	for (NSString *key in [customData allKeys]) {
		[self addCustomData:[customData objectForKey:key] withKey:key toCustomDataDictionary:allowedCustomMessageData];
	}

	return [self.backend presentMessageCenterFromViewController:viewController withCustomData:allowedCustomMessageData];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController {
	return [self didReceiveRemoteNotification:userInfo fromViewController:viewController fetchCompletionHandler:^void(UIBackgroundFetchResult result){
	}];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	NSDictionary *apptentivePayload = [userInfo objectForKey:@"apptentive"];

	if (apptentivePayload != nil) {
		UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
		[self.operationQueue addOperationWithBlock:^{
			BOOL shouldCallCompletionHandler = YES;

			if ([apptentivePayload[@"conversation_id"] isEqualToString:self.backend.conversationManager.activeConversation.identifier]) {
				ApptentiveLogInfo(@"Push notification received for active conversation. userInfo: %@", userInfo);

				switch (applicationState) {
					case UIApplicationStateBackground: {
						NSNumber *contentAvailable = userInfo[@"aps"][@"content-available"];
						if (contentAvailable.boolValue) {
							shouldCallCompletionHandler = NO;
                            if (self.messageManager) {
                                [self.messageManager checkForMessagesInBackground:completionHandler];
                            } else {
                                ApptentiveLogError(@"Can't check for incoming messages: message manager is not initialized");
                            }
						}

						if (userInfo[@"aps"][@"alert"] == nil) {
							ApptentiveLogInfo(@"Silent push notification received. Posting local notification");

							dispatch_async(dispatch_get_main_queue(), ^{
								[self fireLocalNotificationWithUserInfo:userInfo];
							});
						}

						break;
					}
					case UIApplicationStateInactive:
						// Present Apptentive UI later, when Application State is Active
						self.pushUserInfo = userInfo;
						self.pushViewController = viewController;
						break;
					case UIApplicationStateActive:
						self.pushUserInfo = nil;
						self.pushViewController = nil;

						NSString *action = [apptentivePayload objectForKey:@"action"];
						if ([action isEqualToString:@"pmc"]) {
							dispatch_async(dispatch_get_main_queue(), ^{
								[self presentMessageCenterFromViewController:viewController];
							});
						} else {
                            if (self.messageManager) {
                                [self.messageManager checkForMessages];
                            } else {
                                ApptentiveLogError(@"Can't check for incoming messages: message manager is not initialized");
                            }
                            
						}
						break;
				}
			} else {
				ApptentiveLogInfo(@"Push notification received for conversation that is not active. Active conversation ID is %@, push conversation ID is %@", self.backend.conversationManager.activeConversation.identifier, apptentivePayload[@"conversation_id"]);
			}

			if (shouldCallCompletionHandler && completionHandler) {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionHandler(UIBackgroundFetchResultNoData);
				});
			}
		}];
	} else {
		ApptentiveLogInfo(@"Non-apptentive push notification received.");
	}

	return (apptentivePayload != nil);
}

- (BOOL)didReceiveLocalNotification:(UILocalNotification *)notification fromViewController:(UIViewController *)viewController {
	if ([self presentMessageCenterIfNeededForUserInfo:notification.userInfo fromViewController:viewController]) {
		ApptentiveLogInfo(@"Apptentive local notification received.");

		return YES;
	} else {
		ApptentiveLogInfo(@"Non-apptentive local notification received.");

		return NO;
	}
}

- (BOOL)didReceveUserNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
	if ([self presentMessageCenterIfNeededForUserInfo:response.notification.request.content.userInfo fromViewController:nil]) {
		ApptentiveLogInfo(@"Apptentive user notification received.");

		if (completionHandler != nil) {
			completionHandler();
		}

		return YES;
	} else {
		ApptentiveLogInfo(@"Non-apptentive user notification received.");

		return NO;
	}
}

- (BOOL)presentMessageCenterIfNeededForUserInfo:(NSDictionary *)userInfo fromViewController:(nullable UIViewController *)viewController {
	NSDictionary *apptentivePayload = userInfo[@"apptentive"];

	if (apptentivePayload == nil) {
		return NO;
	}

	if ([apptentivePayload[@"action"] isEqualToString:@"pmc"]) {
		[self presentMessageCenterFromViewController:viewController];
	} else {
		if (self.messageManager) {
			[self.messageManager checkForMessages];
		} else {
			ApptentiveLogError(@"Can't check for incoming messages: message manager is not initialized");
		}
	}

	return YES;
}

- (void)fireLocalNotificationWithUserInfo:(NSDictionary *)userInfo {
	ApptentiveLogInfo(@"Silent push notification received. Posting local notification");

	NSString *title = [ApptentiveUtilities appName];
	NSString *body = userInfo[@"apptentive"][@"alert"] ?: NSLocalizedString(@"A new message awaits you in Message Center", @"Default push alert body");
	NSDictionary *apptentiveUserInfo = @{ @"apptentive": userInfo[@"apptentive"] };
	NSString *soundName = userInfo[@"apptentive"][@"sound"];

	if (@available(iOS 10.0, *)) {
		if ([[UNUserNotificationCenter currentNotificationCenter].delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
			UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
			content.title = title;
			content.body = body;
			content.userInfo = apptentiveUserInfo;
			content.sound = [soundName isEqualToString:@"default"] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed:soundName];

			UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
			UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"com.apptentive" content:content trigger:trigger];

			[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
				if (error) {
					ApptentiveLogError(@"Error posting local notification: %@", error);
				}
			}];

			return;
		}
	}

	if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(application:didReceiveLocalNotification:)]) {
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertTitle = title;
		localNotification.alertBody = body;
		localNotification.userInfo = apptentiveUserInfo;
		localNotification.soundName = [soundName isEqualToString:@"default"] ? UILocalNotificationDefaultSoundName : soundName;

		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	} else {
		ApptentiveLogError(@"Your app is not properly configured to accept Apptentive Message Center push notifications.");
		ApptentiveLogError(@"Please see the push notification section of the integration guide for assistance: https://learn.apptentive.com/knowledge-base/ios-integration-reference/#push-notifications");
	}
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(nullable void (^)(void))completion {
	[self.backend dismissMessageCenterAnimated:animated completion:completion];
}

- (NSUInteger)unreadMessageCount {
	return [self.backend unreadMessageCount];
}

- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart {
	if (apptentiveHeart) {
		return [ApptentiveUnreadMessagesBadgeView unreadMessageCountViewBadgeWithApptentiveHeart];
	} else {
		return [ApptentiveUnreadMessagesBadgeView unreadMessageCountViewBadge];
	}
}

#pragma mark - Message notification banner

- (void)showNotificationBannerForMessage:(ApptentiveMessage *)message {
	if (self.backend.configuration.messageCenter.notificationPopupEnabled && [message isKindOfClass:[ApptentiveMessage class]]) {
		// TODO: Display something if body is empty
		ApptentiveMessage *textMessage = (ApptentiveMessage *)message;
		NSURL *profilePhotoURL = textMessage.sender.profilePhotoURL;

		ApptentiveBannerViewController *banner = [ApptentiveBannerViewController bannerWithImageURL:profilePhotoURL title:textMessage.sender.name message:textMessage.body];

		banner.delegate = self;

		[banner show];
	}
}

- (void)userDidTapBanner:(ApptentiveBannerViewController *)banner {
	[self presentMessageCenterFromViewController:[self viewControllerForInteractions]];
}

- (UIViewController *)viewControllerForInteractions {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	if (self.delegate && [self.delegate respondsToSelector:@selector(viewControllerForInteractionsWithConnection:)]) {
		return [self.delegate viewControllerForInteractionsWithConnection:self];
	} else {
		return [ApptentiveUtilities topViewController];
	}
#pragma clang diagnostic pop
}

- (void)dismissAllInteractions:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsShouldDismissNotification object:self userInfo:@{ ApptentiveInteractionsShouldDismissAnimatedKey: @(animated) }];
}

#if APPTENTIVE_DEBUG
- (void)checkSDKConfiguration {
	BOOL hasPhotoLibraryUsageDescription = [[NSBundle mainBundle].infoDictionary objectForKey:@"NSPhotoLibraryUsageDescription"] != nil;

	if (!hasPhotoLibraryUsageDescription) {
		ApptentiveLogError(@"No Photo Library Usage Description Set. This will cause your app to be rejected during app review.");
	}

	BOOL hasAppIDSet = self.appID != nil;

	if (!hasAppIDSet) {
		ApptentiveLogError(@"No App ID set. This may keep the ratings prompt from directing users to your app in the App Store.");
	}

	BOOL hasResources = [ApptentiveUtilities resourceBundle] != nil;

	if (!hasResources) {
		ApptentiveLogError(@"Missing resources.");
#if APPTENTIVE_COCOAPODS
		ApptentiveLogError(@"Try cleaning derived data and/or `pod deintegrate && pod install`.");
#else
		ApptentiveLogError(@"Please make sure the resources are added to the appropriate target(s).");
#endif
	}
}
#endif

#pragma mark - Authentication

- (void)logInWithToken:(NSString *)token completion:(void (^)(BOOL, NSError *_Nonnull))completion {
	void (^wrappingCompletion)(BOOL success, NSError *_Nonnull error) = ^(BOOL success, NSError *_Nonnull error) {
		if (success) {
			[self.backend engageApptentiveAppEvent:@"login"];
		}

		if (completion != nil) {
			completion(success, error);
		}
	};

	[self.operationQueue addOperationWithBlock:^{
		[self.backend.conversationManager logInWithToken:token completion:wrappingCompletion];
	}];
}

- (void)logOut {
	[self dismissAllInteractions:NO];

	[self.operationQueue addOperationWithBlock:^{
		if (self.backend.conversationManager.activeConversation.state != ApptentiveConversationStateLoggedIn) {
			ApptentiveLogError(@"Attempting to log out of a conversation that is not logged in.");
			return;
		}

		[self.backend engageApptentiveAppEvent:@"logout"];

		// To ensure that the logout event payload gets added before the logout payload,
		// use a separate block to run the actual logout operation.
		[self.operationQueue addOperationWithBlock:^{
			[self.backend.conversationManager endActiveConversation];
		}];
	}];
}

- (ApptentiveAuthenticationFailureCallback)authenticationFailureCallback {
	return self.backend.authenticationFailureCallback;
}

- (void)setAuthenticationFailureCallback:(ApptentiveAuthenticationFailureCallback)authenticationFailureCallback {
	self.backend.authenticationFailureCallback = authenticationFailureCallback;
}

#pragma mark -
#pragma mark Notifications

- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification {
	ApptentiveLogMonitor *logMonitor = [ApptentiveLogMonitor sharedInstance];
	if (logMonitor) {
		ApptentiveLogDebug(ApptentiveLogTagMonitor, @"Resuming log monitor...");
		[logMonitor resume];
	} else {
		ApptentiveLogDebug(ApptentiveLogTagMonitor, @"Trying to initialize log monitor...");
		[ApptentiveLogMonitor tryInitializeWithBaseURL:self.baseURL
												appKey:self.apptentiveKey
											 signature:self.apptentiveSignature];
	}
}

#pragma mark -
#pragma mark Logging System

- (ApptentiveLogLevel)logLevel {
	return ApptentiveLogGetLevel();
}

- (void)setLogLevel:(ApptentiveLogLevel)logLevel {
	ApptentiveLogSetLevel(logLevel);
}

#pragma mark -
#pragma mark Operations Queue

- (void)dispatchOnOperationQueue:(void (^)(void))block {
	ApptentiveAssertNotNil(block, @"Attempted to execute a nil block");
	if (block) {
		[_operationQueue addOperationWithBlock:block];
	}
}

#pragma mark -
#pragma mark Properties

- (ApptentiveMessageManager *)messageManager {
	return self.backend.conversationManager.messageManager;
}

@end

@interface ApptentiveNavigationController ()

@property (nullable, nonatomic, strong) UIWindow *apptentiveAlertWindow;

@end

@implementation ApptentiveNavigationController

// Container to allow customization of Apptentive UI using UIAppearance

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {

		if (!([UINavigationBar appearance].barTintColor || [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [ApptentiveNavigationController class] ]].barTintColor)) {
			[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [ApptentiveNavigationController class] ]].barTintColor = [UIColor whiteColor];
		}
	}
	return self;
}

- (void)presentAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion {
	self.apptentiveAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.apptentiveAlertWindow.rootViewController = [[UIViewController alloc] init];
	self.apptentiveAlertWindow.windowLevel = UIWindowLevelAlert + 1;
	[self.apptentiveAlertWindow makeKeyAndVisible];
	[self.apptentiveAlertWindow.rootViewController presentViewController:self animated:animated completion:completion];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	if (self.presentingViewController == nil) {
		self.apptentiveAlertWindow.hidden = YES;
		self.apptentiveAlertWindow = nil;
	}
}

- (void)pushAboutApptentiveViewController {
	UIViewController *aboutViewController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"About"];
	[self pushViewController:aboutViewController animated:YES];
}

@end

NSString *ApptentiveLocalizedString(NSString *key, NSString * _Nullable comment) {
	static NSBundle *bundle = nil;
	if (!bundle) {
		bundle = [ApptentiveUtilities resourceBundle];
	}
	NSString *result = [bundle localizedStringForKey:key value:key table:nil];
	return result;
}

ApptentiveAuthenticationFailureReason parseAuthenticationFailureReason(NSString *reason) {
	if ([reason isEqualToString:@"INVALID_ALGORITHM"]) {
		return ApptentiveAuthenticationFailureReasonInvalidAlgorithm;
	}
	if ([reason isEqualToString:@"MALFORMED_TOKEN"]) {
		return ApptentiveAuthenticationFailureReasonMalformedToken;
	}
	if ([reason isEqualToString:@"INVALID_TOKEN"]) {
		return ApptentiveAuthenticationFailureReasonInvalidToken;
	}
	if ([reason isEqualToString:@"MISSING_SUB_CLAIM"]) {
		return ApptentiveAuthenticationFailureReasonMissingSubClaim;
	}
	if ([reason isEqualToString:@"MISMATCHED_SUB_CLAIM"]) {
		return ApptentiveAuthenticationFailureReasonMismatchedSubClaim;
	}
	if ([reason isEqualToString:@"INVALID_SUB_CLAIM"]) {
		return ApptentiveAuthenticationFailureReasonInvalidSubClaim;
	}
	if ([reason isEqualToString:@"EXPIRED_TOKEN"]) {
		return ApptentiveAuthenticationFailureReasonExpiredToken;
	}
	if ([reason isEqualToString:@"REVOKED_TOKEN"]) {
		return ApptentiveAuthenticationFailureReasonRevokedToken;
	}
	if ([reason isEqualToString:@"MISSING_APP_KEY"]) {
		return ApptentiveAuthenticationFailureReasonMissingAppKey;
	}
	if ([reason isEqualToString:@"MISSING_APP_SIGNATURE"]) {
		return ApptentiveAuthenticationFailureReasonMissingAppSignature;
	}
	if ([reason isEqualToString:@"INVALID_KEY_SIGNATURE_PAIR"]) {
		return ApptentiveAuthenticationFailureReasonInvalidKeySignaturePair;
	}
	return ApptentiveAuthenticationFailureReasonUnknown;
}

NS_ASSUME_NONNULL_END
