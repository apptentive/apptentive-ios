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

NSString *const ApptentiveMessageCenterUnreadCountChangedNotification = @"ApptentiveMessageCenterUnreadCountChangedNotification";

NSString *const ApptentiveAppRatingFlowUserAgreedToRateAppNotification = @"ApptentiveAppRatingFlowUserAgreedToRateAppNotification";

NSString *const ApptentiveSurveyShownNotification = @"ApptentiveSurveyShownNotification";
NSString *const ApptentiveSurveySentNotification = @"ApptentiveSurveySentNotification";
NSString *const ApptentiveSurveyIDKey = @"ApptentiveSurveyIDKey";

NSString *const ApptentiveCustomPersonDataChangedNotification = @"ApptentiveCustomPersonDataChangedNotification";
NSString *const ApptentiveCustomDeviceDataChangedNotification = @"ApptentiveCustomDeviceDataChangedNotification";
NSString *const ApptentiveInteractionsDidUpdateNotification = @"ApptentiveInteractionsDidUpdateNotification";
NSString *const ApptentiveConversationCreatedNotification = @"ApptentiveConversationCreatedNotification";

NSString *const ApptentiveCustomDeviceDataPreferenceKey = @"ApptentiveCustomDeviceDataPreferenceKey";
NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";

NSString *const ApptentivePushProviderPreferenceKey = @"ApptentivePushProviderPreferenceKey";
NSString *const ApptentivePushTokenPreferenceKey = @"ApptentivePushTokenPreferenceKey";

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
		ApptentiveLogSetLevel(configuration.logLevel);

		_style = [[ApptentiveStyleSheet alloc] init];
		_apptentiveKey = configuration.apptentiveKey;
		_apptentiveSignature = configuration.apptentiveSignature;
		_baseURL = configuration.baseURL;
		_backend = [[ApptentiveBackend alloc] initWithApptentiveKey:_apptentiveKey
														  signature:_apptentiveSignature
															baseURL:_baseURL
														storagePath:@"com.apptentive.feedback"];

		if (configuration.distributionName && configuration.distributionVersion) {
			[ApptentiveSDK setDistributionName:configuration.distributionName];
			[ApptentiveSDK setDistributionVersion:[[ApptentiveVersion alloc] initWithString:configuration.distributionVersion]];
		}

		ApptentiveLogInfo(@"Apptentive SDK Version %@", [ApptentiveSDK SDKVersion].versionString);
	}
	return self;
}

+ (void)registerWithConfiguration:(ApptentiveConfiguration *)configuration {
	if (_sharedInstance != nil) {
		ApptentiveLogWarning(@"Apptentive instance is already initialized");
		return;
	}
	_sharedInstance = [[Apptentive alloc] initWithConfiguration:configuration];
}

- (id<ApptentiveStyle>)styleSheet {
	[self.backend.conversationManager.activeConversation didOverrideStyles];

	return _style;
}

- (void)setStyleSheet:(id<ApptentiveStyle>)style {
	_style = style;

	[self.backend.conversationManager.activeConversation didOverrideStyles];
}

- (NSString *)personName {
	return self.backend.conversationManager.activeConversation.person.name;
}

- (void)setPersonName:(NSString *)personName {
	self.backend.conversationManager.activeConversation.person.name = personName;
	[self.backend schedulePersonUpdate];
}

- (NSString *)personEmailAddress {
	return self.backend.conversationManager.activeConversation.person.emailAddress;
}

- (void)setPersonEmailAddress:(NSString *)personEmailAddress {
	self.backend.conversationManager.activeConversation.person.emailAddress = personEmailAddress;
	[self.backend schedulePersonUpdate];
}

- (void)sendAttachmentText:(NSString *)text {
	ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:text attachments:nil senderIdentifier:self.backend.conversationManager.messageManager.localUserIdentifier automated:NO customData:nil];
	ApptentiveAssertNotNil(message, @"Message is nil");

	if (message != nil) {
		[self.backend.conversationManager.messageManager enqueueMessageForSending:message];
	}
}

- (void)sendAttachmentImage:(UIImage *)image {
	if (image == nil) {
		ApptentiveLogError(@"Unable to send image attachment: image is nil");
		return;
	}

	NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
	if (imageData == nil) {
		ApptentiveLogError(@"Unable to send image attachment: image data is invalid");
		return;
	}

	ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithData:imageData contentType:@"image/jpeg" name:nil];
	ApptentiveAssertNotNil(attachment, @"Attachment is nil");
	if (attachment != nil) {
		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:nil attachments:@[attachment] senderIdentifier:self.backend.conversationManager.messageManager.localUserIdentifier automated:NO customData:nil];
		ApptentiveAssertNotNil(message, @"Message is nil");

		if (message != nil) {
			[self.backend.conversationManager.messageManager enqueueMessageForSending:message];
		}
	}
}

- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType {
	if (fileData == nil) {
		ApptentiveLogError(@"Unable to send attachment file: file data is nil");
		return;
	}

	if (mimeType.length == 0) {
		ApptentiveLogError(@"Unable to send attachment file: mime-type is nil or empty");
		return;
	}

	ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithData:fileData contentType:mimeType name:nil];
	ApptentiveAssertNotNil(attachment, @"Attachment is nil");

	if (attachment != nil) {
		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:nil attachments:@[attachment] senderIdentifier:self.backend.conversationManager.messageManager.localUserIdentifier automated:NO customData:nil];

		ApptentiveAssertNotNil(message, @"Message is nil");
		if (message != nil) {
			[self.backend.conversationManager.messageManager enqueueMessageForSending:message];
		}
	}
}

- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.device addCustomString:string withKey:key];
	[self.backend scheduleDeviceUpdate];
}

- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.device addCustomNumber:number withKey:key];
	[self.backend scheduleDeviceUpdate];
}

- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.device addCustomBool:boolValue withKey:key];
	[self.backend scheduleDeviceUpdate];
}

- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.person addCustomString:string withKey:key];
	[self.backend schedulePersonUpdate];
}

- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.person addCustomNumber:number withKey:key];
	[self.backend schedulePersonUpdate];
}

- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.person addCustomBool:boolValue withKey:key];
	[self.backend schedulePersonUpdate];
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
		[customData setObject:object forKey:key];
	} else {
		ApptentiveLogError(@"Apptentive custom data must be of type NSString, NSNumber, or NSNull, or a 'complex type' NSDictionary created by one of the constructors in Apptentive.h");
	}
}

- (void)removeCustomPersonDataWithKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.person removeCustomValueWithKey:key];
	[self.backend schedulePersonUpdate];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[self.backend.conversationManager.activeConversation.device removeCustomValueWithKey:key];
	[self.backend scheduleDeviceUpdate];
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
	return self.backend.conversationManager.activeConversation.device.integrationConfiguration;
}

- (void)setPushNotificationIntegration:(ApptentivePushProvider)pushProvider withDeviceToken:(NSData *)deviceToken {
	const unsigned *tokenBytes = [deviceToken bytes];
	NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
								ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
								ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
								ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

	// save push token and provider in user defaults
	[[NSUserDefaults standardUserDefaults] setInteger:pushProvider forKey:ApptentivePushProviderPreferenceKey];
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:ApptentivePushTokenPreferenceKey];

	if (self.backend.conversationManager.activeConversation) {
		[self.backend.conversationManager.activeConversation setPushToken:token provider:pushProvider];
		[self.backend scheduleDeviceUpdate];
	}
}

- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration {
	NSMutableDictionary *integrationConfiguration = [self.backend.conversationManager.activeConversation.device.integrationConfiguration mutableCopy];
	[integrationConfiguration setObject:configuration forKey:integration];
	self.backend.conversationManager.activeConversation.device.integrationConfiguration = integrationConfiguration;
	[self.backend scheduleDeviceUpdate];
}

- (void)removeIntegration:(NSString *)integration {
	NSMutableDictionary *integrationConfiguration = [self.backend.conversationManager.activeConversation.device.integrationConfiguration mutableCopy];
	[integrationConfiguration removeObjectForKey:integration];
	self.backend.conversationManager.activeConversation.device.integrationConfiguration = integrationConfiguration;
	[self.backend scheduleDeviceUpdate];
}

- (BOOL)canShowInteractionForEvent:(NSString *)event {
	return [self.backend canShowInteractionForLocalEvent:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:customData withExtendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [self.backend engageLocalEvent:event userInfo:nil customData:customData extendedData:extendedData fromViewController:viewController];
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


+ (NSDictionary *)extendedDataCommerceWithTransactionID:(NSString *)transactionID
											affiliation:(NSString *)affiliation
												revenue:(NSNumber *)revenue
											   shipping:(NSNumber *)shipping
													tax:(NSNumber *)tax
											   currency:(NSString *)currency
										  commerceItems:(NSArray *)commerceItems {
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

+ (NSDictionary *)extendedDataCommerceItemWithItemID:(NSString *)itemID
												name:(NSString *)name
											category:(NSString *)category
											   price:(NSNumber *)price
											quantity:(NSNumber *)quantity
											currency:(NSString *)currency {
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

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController {
	return [self.backend presentMessageCenterFromViewController:viewController];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
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
		BOOL shouldCallCompletionHandler = YES;

		if ([apptentivePayload[@"conversationId"] isEqualToString:self.backend.conversationManager.activeConversation.identifier]) {
			ApptentiveLogInfo(@"Push notification received for active conversation. userInfo: %@", userInfo);

			switch ([UIApplication sharedApplication].applicationState) {
				case UIApplicationStateBackground: {
					NSNumber *contentAvailable = userInfo[@"aps"][@"content-available"];
					if (contentAvailable.boolValue) {
						shouldCallCompletionHandler = NO;
						[self.backend.conversationManager.messageManager checkForMessagesInBackground:completionHandler];
					}

					if (userInfo[@"aps"][@"alert"] == nil) {
						ApptentiveLogInfo(@"Silent push notification received. Posting local notification");

						UILocalNotification *localNotification = [[UILocalNotification alloc] init];
						localNotification.alertTitle = [ApptentiveUtilities appName];
						localNotification.alertBody = userInfo[@"apptentive"][@"alert"];
						localNotification.userInfo = @{ @"apptentive": apptentivePayload };

						NSString *soundName = userInfo[@"apptentive"][@"sound"];
						if ([soundName isEqualToString:@"default"]) {
							soundName = UILocalNotificationDefaultSoundName;
						}

						localNotification.soundName = soundName;

						[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
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
						[self presentMessageCenterFromViewController:viewController];
					} else {
						[self.backend.conversationManager.messageManager checkForMessages];
					}
					break;
			}
		} else {
			ApptentiveLogInfo(@"Push notification received for conversation that is not active.");
		}

		if (shouldCallCompletionHandler && completionHandler) {
			completionHandler(UIBackgroundFetchResultNoData);
		}
	} else {
		ApptentiveLogInfo(@"Non-apptentive push notification received.");
	}

	return (apptentivePayload != nil);
}

- (BOOL)didReceiveLocalNotification:(UILocalNotification *)notification fromViewController:(UIViewController *)viewController {
	NSDictionary *apptentivePayload = [notification.userInfo objectForKey:@"apptentive"];

	if (apptentivePayload != nil) {
		ApptentiveLogInfo(@"Apptentive local notification received.");

		NSString *action = [apptentivePayload objectForKey:@"action"];
		if ([action isEqualToString:@"pmc"]) {
			[self presentMessageCenterFromViewController:viewController];
		} else {
			[self.backend.conversationManager.messageManager checkForMessages];
		}
		return YES;
	}

	ApptentiveLogInfo(@"Non-apptentive local notification received.");

	return NO;
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
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
	if (self.delegate && [self.delegate respondsToSelector:@selector(viewControllerForInteractionsWithConnection:)]) {
		return [self.delegate viewControllerForInteractionsWithConnection:self];
	} else {
		return [ApptentiveUtilities topViewController];
	}
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
	[self.backend.conversationManager logInWithToken:token completion:completion];
}

- (void)logOut {
	[self.backend.conversationManager endActiveConversation];
}

- (ApptentiveAuthenticationFailureCallback)authenticationFailureCallback {
    return self.backend.authenticationFailureCallback;
}

- (void)setAuthenticationFailureCallback:(ApptentiveAuthenticationFailureCallback)authenticationFailureCallback {
    self.backend.authenticationFailureCallback = authenticationFailureCallback;
}

#pragma mark -
#pragma mark Logging System

- (ApptentiveLogLevel)logLevel {
	return ApptentiveLogGetLevel();
}

- (void)setLogLevel:(ApptentiveLogLevel)logLevel {
	ApptentiveLogSetLevel(logLevel);
}

@end


@implementation ApptentiveNavigationController
// Container to allow customization of Apptentive UI using UIAppearance

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		if (!([UINavigationBar appearance].barTintColor || [UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor)) {
			[UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor = [UIColor whiteColor];
		}
	}
	return self;
}

- (void)pushAboutApptentiveViewController {
	UIViewController *aboutViewController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"About"];
	[self pushViewController:aboutViewController animated:YES];
}

@end

NSString *ApptentiveLocalizedString(NSString *key, NSString *comment) {
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
