//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATConnect+Debugging.h"
#import "ATBackend.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"
#import "ATUtilities.h"
#import "ATAppConfigurationUpdater.h"
#import "ATMessageSender.h"
#import "ATWebClient.h"
#import "ATPersonInfo.h"
#import "ATDeviceInfo.h"
#if TARGET_OS_IPHONE
#import "ATMessageCenterViewController.h"
#import "ATBannerViewController.h"
#import "ATUnreadMessagesBadgeView.h"
#endif

// Can't get CocoaPods to do the right thing for debug builds.
// So, do it explicitly.
#if COCOAPODS
#if DEBUG
#define APPTENTIVE_DEBUG_LOG_VIEWER 1
#endif
#endif

NSString *const ATMessageCenterUnreadCountChangedNotification = @"ATMessageCenterUnreadCountChangedNotification";

NSString *const ATAppRatingFlowUserAgreedToRateAppNotification = @"ATAppRatingFlowUserAgreedToRateAppNotification";

NSString *const ATSurveyShownNotification = @"ATSurveyShownNotification";
NSString *const ATSurveySentNotification = @"ATSurveySentNotification";
NSString *const ATSurveyIDKey = @"ATSurveyIDKey";

@interface ATConnect () <ATBannerViewControllerDelegate>
@end


@implementation ATConnect

+ (void)load {
	[UINavigationBar appearanceWhenContainedIn:[ATNavigationController class], nil].barTintColor = [UIColor whiteColor];
}

+ (NSString *)supportDirectoryPath {
	NSString *appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
	NSString *apptentiveDirectoryPath = [appSupportDirectoryPath stringByAppendingPathComponent:@"com.apptentive.feedback"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;

	if (![fm createDirectoryAtPath:apptentiveDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
		ATLogError(@"Failed to create support directory: %@", apptentiveDirectoryPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}

	if (![fm setAttributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication } ofItemAtPath:apptentiveDirectoryPath error:&error]) {
		ATLogError(@"Failed to set file protection level: %@", apptentiveDirectoryPath);
		ATLogError(@"Error was: %@", error);
	}

	return apptentiveDirectoryPath;
}

+ (ATConnect *)sharedConnection {
	static ATConnect *_sharedConnection = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedConnection = [[ATConnect alloc] init];
	});
	return _sharedConnection;
}

- (instancetype)init {
	if ((self = [super init])) {
		self.showEmailField = YES;
		_integrationConfiguration = [[NSMutableDictionary alloc] init];

		ATLogInfo(@"Apptentive SDK Version %@", kATConnectVersionString);
	}
	return self;
}

- (void)setApiKey:(NSString *)APIKey {
	[self setAPIKey:APIKey baseURL:[NSURL URLWithString:@"https://api.apptentive.com"] storagePath:[[self class] supportDirectoryPath]];
}

- (NSString *)apiKey {
	return self.webClient.APIKey;
}

- (NSString *)personName {
	return self.backend.currentPerson.name;
}

- (void)setPersonName:(NSString *)personName {
	self.backend.currentPerson.name = personName;
}

- (NSString *)personEmailAddress {
	return self.backend.currentPerson.emailAddress;
}

- (void)setPersonEmailAddress:(NSString *)personEmailAddress {
	self.backend.currentPerson.emailAddress = personEmailAddress;
}

- (UIColor *)tintColor {
	return [UIView appearanceWhenContainedIn:[ATNavigationController class], nil].tintColor;
}

- (void)setTintColor:(UIColor *)tintColor {
	[UIView appearanceWhenContainedIn:[ATNavigationController class], nil].tintColor = tintColor;
}

- (void)sendAttachmentText:(NSString *)text {
	[self.backend sendTextMessageWithBody:text hiddenOnClient:YES];
}

- (void)sendAttachmentImage:(UIImage *)image {
	[self.backend sendImageMessageWithImage:image hiddenOnClient:YES];
}

- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType {
	[self.backend sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:YES];
}

- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.currentDevice setCustomDataString:string forKey:key];
}

- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.currentDevice setCustomDataNumber:number forKey:key];
}

- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.currentDevice setCustomDataBool:boolValue forKey:key];
}

- (void)addCustomDeviceData:(NSObject<NSCoding> *)data withKey:(NSString *)key {
	[self.backend.currentDevice setCustomData:data forKey:key];
}

- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key {
	[self addCustomDeviceData:object withKey:key];
}

- (void)removeCustomDataWithKey:(NSString *)key {
	[self removeCustomDeviceDataWithKey:key];
}

- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.currentPerson setCustomDataString:string forKey:key];
}

- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.currentPerson setCustomDataNumber:number forKey:key];
}

- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.currentPerson setCustomDataBool:boolValue forKey:key];
}

- (void)addCustomPersonData:(NSObject<NSCoding> *)data withKey:(NSString *)key {
	[self.backend.currentPerson setCustomData:data forKey:key];
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
		ATLogError(@"Apptentive custom data must be of type NSString, NSNumber, or NSNull, or a 'complex type' NSDictionary created by one of the constructors in ATConnect.h");
	}
}

- (void)removeCustomPersonDataWithKey:(NSString *)key {
	[self.backend.currentPerson removeCustomDataForKey:key];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[self.backend.currentDevice removeCustomDataForKey:key];
}

- (void)openAppStore {
	if (!self.appID) {
		ATLogError(@"Cannot open App Store because `[ATConnect sharedConnection].appID` is not set to your app's iTunes App ID.");
		return;
	}

	[self.engagementBackend engageApptentiveAppEvent:@"open_app_store_manually"];

	ATInteraction *appStoreInteraction = [[ATInteraction alloc] init];
	appStoreInteraction.type = @"AppStoreRating";
	appStoreInteraction.priority = 1;
	appStoreInteraction.version = @"1.0.0";
	appStoreInteraction.identifier = @"OpenAppStore";
	appStoreInteraction.configuration = @{ @"store_id": self.appID,
		@"method": @"app_store" };

	[self.engagementBackend presentInteraction:appStoreInteraction fromViewController:nil];
}

- (void)setPushNotificationIntegration:(ATPushProvider)pushProvider withDeviceToken:(NSData *)deviceToken {
	[self removeAllPushIntegrations];

	NSString *integrationKey = [self integrationKeyForPushProvider:pushProvider];

	[self addIntegration:integrationKey withDeviceToken:deviceToken];
}

- (void)removeAllPushIntegrations {
	[self removeIntegration:[self integrationKeyForPushProvider:ATPushProviderApptentive]];
	[self removeIntegration:[self integrationKeyForPushProvider:ATPushProviderUrbanAirship]];
	[self removeIntegration:[self integrationKeyForPushProvider:ATPushProviderAmazonSNS]];
	[self removeIntegration:[self integrationKeyForPushProvider:ATPushProviderParse]];
}

- (NSString *)integrationKeyForPushProvider:(ATPushProvider)pushProvider {
	switch (pushProvider) {
		case ATPushProviderApptentive:
			return @"apptentive_push";
		case ATPushProviderUrbanAirship:
			return @"urban_airship";
		case ATPushProviderAmazonSNS:
			return @"aws_sns";
		case ATPushProviderParse:
			return @"parse";
		default:
			return @"UNKNOWN_PUSH_PROVIDER";
	}
}

- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration {
	[_integrationConfiguration setObject:configuration forKey:integration];

	[[NSNotificationCenter defaultCenter] postNotificationName:ATDataNeedsSaveNotification object:_integrationConfiguration];
}

- (void)addIntegration:(NSString *)integration withDeviceToken:(NSData *)deviceToken {
	const unsigned *tokenBytes = [deviceToken bytes];
	NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
								ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
								ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
								ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

	[self addIntegration:integration withConfiguration:@{ @"token": token }];
}

- (void)removeIntegration:(NSString *)integration {
	[_integrationConfiguration removeObjectForKey:integration];

	[[NSNotificationCenter defaultCenter] postNotificationName:ATDataNeedsSaveNotification object:_integrationConfiguration];
}

#if TARGET_OS_IPHONE

- (BOOL)willShowInteractionForEvent:(NSString *)event {
	return [self canShowInteractionForEvent:event];
}

- (BOOL)canShowInteractionForEvent:(NSString *)event {
	return [self.engagementBackend canShowInteractionForLocalEvent:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:customData withExtendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [self.engagementBackend engageLocalEvent:event userInfo:nil customData:customData extendedData:extendedData fromViewController:viewController];
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
	NSString *messageCenterCodePoint = [[ATInteraction apptentiveAppInteraction] codePointForEvent:ATEngagementMessageCenterEvent];
	return [self.engagementBackend canShowInteractionForCodePoint:messageCenterCodePoint];
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
	if (apptentivePayload) {
		BOOL shouldCallCompletionHandler = YES;

		switch ([UIApplication sharedApplication].applicationState) {
			case UIApplicationStateBackground: {
				NSNumber *contentAvailable = userInfo[@"aps"][@"content-available"];
				if (contentAvailable.boolValue) {
					shouldCallCompletionHandler = NO;
					[self.backend fetchMessagesInBackground:completionHandler];
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
					[self.backend checkForMessages];
				}
				break;
		}

		if (shouldCallCompletionHandler && completionHandler) {
			completionHandler(UIBackgroundFetchResultNoData);
		}
	}

	return (apptentivePayload != nil);
}

- (void)resetUpgradeData {
	[self.engagementBackend resetUpgradeVersionInfo];
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[self.backend dismissMessageCenterAnimated:animated completion:completion];
}

- (NSUInteger)unreadMessageCount {
	return [self.backend unreadMessageCount];
}

- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart {
	if (apptentiveHeart) {
		return [ATUnreadMessagesBadgeView unreadMessageCountViewBadgeWithApptentiveHeart];
	} else {
		return [ATUnreadMessagesBadgeView unreadMessageCountViewBadge];
	}
}

#elif TARGET_OS_MAC
- (IBAction)showFeedbackWindow:(id)sender {
	if (![self.backend currentFeedback]) {
		ATFeedback *feedback = [[ATFeedback alloc] init];
		if (additionalFeedbackData && [additionalFeedbackData count]) {
			[feedback addExtraDataFromDictionary:additionalFeedbackData];
		}
		if (self.initialName && [self.initialName length] > 0) {
			feedback.name = self.initialName;
		}
		if (self.initialEmailAddress && [self.initialEmailAddress length] > 0) {
			feedback.email = self.initialEmailAddress;
		}
		[self.backend setCurrentFeedback:feedback];
		[feedback release];
		feedback = nil;
	}

	if (!feedbackWindowController) {
		feedbackWindowController = [[ATFeedbackWindowController alloc] initWithFeedback:[self.backend currentFeedback]];
	}
	[feedbackWindowController showWindow:self];
}
#endif

+ (NSBundle *)resourceBundle {
#if TARGET_OS_IPHONE
	NSString *path = [[NSBundle bundleForClass:[ATBackend class]] bundlePath];
	NSString *bundlePath = [path stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:bundlePath]) {
		NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
		return bundle;
	} else {
		// Try trigger.io path.
		bundlePath = [path stringByAppendingPathComponent:@"apptentive.bundle"];
		bundlePath = [bundlePath stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
		if ([fm fileExistsAtPath:bundlePath]) {
			NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
			return bundle;
		} else {
			// Try Titanium path.
			bundlePath = [path stringByAppendingPathComponent:@"modules"];
			bundlePath = [bundlePath stringByAppendingPathComponent:@"com.apptentive.titanium"];
			bundlePath = [bundlePath stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
			if ([fm fileExistsAtPath:bundlePath]) {
				NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
				return bundle;
			} else {
				return nil;
			}
		}
	}
#elif TARGET_OS_MAC
	NSBundle *bundle = [NSBundle bundleForClass:[ATConnect class]];
	return bundle;
#endif
}

#pragma mark - Message notification banner

- (void)showNotificationBannerForMessage:(ATMessage *)message {
	if (self.backend.notificationPopupsEnabled && [message isKindOfClass:[ATMessage class]]) {
		// TODO: Display something if body is empty
		ATMessage *textMessage = (ATMessage *)message;
		NSURL *profilePhotoURL = textMessage.sender.profilePhotoURL ? [NSURL URLWithString:textMessage.sender.profilePhotoURL] : nil;

		ATBannerViewController *banner = [ATBannerViewController bannerWithImageURL:profilePhotoURL title:textMessage.sender.name message:textMessage.body];

		banner.delegate = self;

		[banner show];
	}
}

- (void)userDidTapBanner:(ATBannerViewController *)banner {
	[self presentMessageCenterFromViewController:[self viewControllerForInteractions]];
}

- (UIViewController *)viewControllerForInteractions {
	if (self.delegate && [self.delegate respondsToSelector:@selector(viewControllerForInteractionsWithConnection:)]) {
		return [self.delegate viewControllerForInteractionsWithConnection:self];
	} else {
		return [ATUtilities topViewController];
	}
}

+ (UIStoryboard *)storyboard {
	return [UIStoryboard storyboardWithName:@"Apptentive" bundle:[ATConnect resourceBundle]];
}

#pragma mark - Debugging and diagnostics

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath {
	if (![APIKey isEqualToString:self.webClient.APIKey] || ![baseURL isEqual:self.webClient.baseURL]) {
		_webClient = [[ATWebClient alloc] initWithBaseURL:baseURL APIKey:APIKey];

		_backend = [[ATBackend alloc] initWithStoragePath:storagePath];
		_engagementBackend = [[ATEngagementBackend alloc] init];

		[self.backend startup];
	}
}

- (NSString *)storagePath {
	return self.backend.storagePath;
}

@end


@implementation ATNavigationController
// Container to allow customization of Apptentive UI using UIAppearance
@end

NSString *ATLocalizedString(NSString *key, NSString *comment) {
	static NSBundle *bundle = nil;
	if (!bundle) {
		bundle = [ATConnect resourceBundle];
	}
	NSString *result = [bundle localizedStringForKey:key value:key table:nil];
	return result;
}
