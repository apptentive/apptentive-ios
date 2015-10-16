//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATConnect_Debugging.h"
#import "ATBackend.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"
#import "ATUtilities.h"
#import "ATAppConfigurationUpdater.h"
#import "ATMessageSender.h"
#if TARGET_OS_IPHONE
#import "ATMessageCenterViewController.h"
#import "ATBannerViewController.h"
#import "ATUnreadMessagesBadgeView.h"
#endif

// Can't get CocoaPods to do the right thing for debug builds.
// So, do it explicitly.
#if COCOAPODS
#    if DEBUG
#	     define APPTENTIVE_DEBUG_LOG_VIEWER 1
#    endif
#endif

NSString *const ATMessageCenterUnreadCountChangedNotification = @"ATMessageCenterUnreadCountChangedNotification";

NSString *const ATAppRatingFlowUserAgreedToRateAppNotification = @"ATAppRatingFlowUserAgreedToRateAppNotification";

NSString *const ATSurveyShownNotification = @"ATSurveyShownNotification";
NSString *const ATSurveySentNotification = @"ATSurveySentNotification";
NSString *const ATSurveyIDKey = @"ATSurveyIDKey";

NSString *const ATConnectCustomPersonDataChangedNotification = @"ATConnectCustomPersonDataChangedNotification";
NSString *const ATConnectCustomDeviceDataChangedNotification = @"ATConnectCustomDeviceDataChangedNotification";

@interface ATConnect () <ATBannerViewControllerDelegate>
@end

@implementation ATConnect {
	NSMutableDictionary *_customPersonData;
	NSMutableDictionary *_customDeviceData;
	NSMutableDictionary *_integrationConfiguration;
}

+ (void)load {
	[UINavigationBar appearanceWhenContainedIn:[ATNavigationController class], nil].barTintColor = [UIColor whiteColor];
}

+ (ATConnect *)sharedConnection {
	static ATConnect *sharedConnection = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConnection = [[ATConnect alloc] init];
	});
	return sharedConnection;
}

- (id)init {
	if ((self = [super init])) {
		self.showEmailField = YES;
		_customPersonData = [[NSMutableDictionary alloc] init];
		_customDeviceData = [[NSMutableDictionary alloc] init];
		_integrationConfiguration = [[NSMutableDictionary alloc] init];
		
		ATLogInfo(@"Apptentive SDK Version %@", kATConnectVersionString);
		
#if APPTENTIVE_DEBUG_LOG_VIEWER
		self.debuggingOptions = ATConnectDebuggingOptionsShowDebugPanel;
#endif
	}
	return self;
}

- (void)setApiKey:(NSString *)APIKey {
	if (_apiKey != APIKey) {
		_apiKey = APIKey;
		[[ATBackend sharedBackend] setApiKey:self.apiKey];
	}
}

- (NSString *)personName {
	return [ATPersonInfo currentPerson].name;
}

- (void)setPersonName:(NSString *)personName {
	[ATPersonInfo currentPerson].name = personName;
}

- (NSString *)personEmailAddress {
	return [ATPersonInfo currentPerson].emailAddress;
}

- (void)setPersonEmailAddress:(NSString *)personEmailAddress {
	[ATPersonInfo currentPerson].emailAddress = personEmailAddress;
}

- (UIColor *)tintColor {
	return [UIView appearanceWhenContainedIn:[ATNavigationController class], nil].tintColor;
}

- (void)setTintColor:(UIColor *)tintColor {
	[UIView appearanceWhenContainedIn:[ATNavigationController class], nil].tintColor = tintColor;
}

- (void)sendAttachmentText:(NSString *)text {
	[[ATBackend sharedBackend] sendTextMessageWithBody:text hiddenOnClient:YES];
}

- (void)sendAttachmentImage:(UIImage *)image {
	[[ATBackend sharedBackend] sendImageMessageWithImage:image hiddenOnClient:YES fromSource:ATFeedbackImageSourceProgrammatic];
}

- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType {
	[[ATBackend sharedBackend] sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:YES fromSource:ATFileAttachmentSourceProgrammatic];
}

- (NSDictionary *)customPersonData {
	return _customPersonData;
}

- (NSDictionary *)customDeviceData {
	return _customDeviceData;
}

- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key {
	[self addCustomDeviceData:string withKey:key];
}

- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self addCustomDeviceData:number withKey:key];
}

- (void)addCustomDeviceDataBOOL:(BOOL)boolValue withKey:(NSString *)key {
	[self addCustomDeviceData:@(boolValue) withKey:key];
}

- (void)addCustomDeviceDataVersion:(NSDictionary *)versionObject withKey:(NSString *)key {
	[self addCustomDeviceData:versionObject withKey:key];
}

- (void)addCustomDeviceDataTimestamp:(NSDictionary *)timestampObject withKey:(NSString *)key {
	[self addCustomDeviceData:timestampObject withKey:key];
}

- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key {
	[self addCustomPersonData:string withKey:key];
}

- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self addCustomPersonData:number withKey:key];
}

- (void)addCustomPersonDataBOOL:(BOOL)boolValue withKey:(NSString *)key {
	[self addCustomPersonData:@(boolValue) withKey:key];
}

- (void)addCustomPersonDataVersion:(NSDictionary *)versionObject withKey:(NSString *)key {
	[self addCustomPersonData:versionObject withKey:key];
}

- (void)addCustomPersonDataTimestamp:(NSDictionary *)timestampObject withKey:(NSString *)key {
	[self addCustomPersonData:timestampObject withKey:key];
}

- (NSDictionary *)versionObjectWithVersion:(NSString *)version {
	return @{@"_type": @"version",
			 @"code": version ?: [NSNull null],
			 };
}

- (NSDictionary *)timestampObjectWithDate:(NSDate *)date {
	return @{@"_type": @"timestamp",
			 @"sec": @([date timeIntervalSince1970]),
			 };
}

- (void)addCustomPersonData:(NSObject *)object withKey:(NSString *)key {
	[self addCustomData:object withKey:key toCustomDataDictionary:_customPersonData];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomPersonDataChangedNotification object:self.customPersonData];
}

- (void)addCustomDeviceData:(NSObject *)object withKey:(NSString *)key {
	[self addCustomData:object withKey:key toCustomDataDictionary:_customDeviceData];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomDeviceDataChangedNotification object:self.customDeviceData];
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
	[_customPersonData removeObjectForKey:key];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomPersonDataChangedNotification object:self.customPersonData];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[_customDeviceData removeObjectForKey:key];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomDeviceDataChangedNotification object:self.customDeviceData];
}

- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key {
	[self addCustomDeviceData:object withKey:key];
}

- (void)removeCustomDataWithKey:(NSString *)key {
	[self removeCustomDeviceDataWithKey:key];
}

- (void)openAppStore {
	if (!self.appID) {
		ATLogError(@"Cannot open App Store because `[ATConnect sharedConnection].appID` is not set to your app's iTunes App ID.");
		return;
	}
	
	[[ATEngagementBackend sharedBackend] engageApptentiveAppEvent:@"open_app_store_manually"];
	
	ATInteraction *appStoreInteraction = [[ATInteraction alloc] init];
	appStoreInteraction.type = @"AppStoreRating";
	appStoreInteraction.priority = 1;
	appStoreInteraction.version = @"1.0.0";
	appStoreInteraction.identifier = @"OpenAppStore";
	appStoreInteraction.configuration = @{@"store_id": self.appID,
										  @"method": @"app_store"};
	
	[[ATEngagementBackend sharedBackend] presentInteraction:appStoreInteraction fromViewController:nil];
}

- (NSDictionary *)integrationConfiguration {
	return _integrationConfiguration;
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomDeviceDataChangedNotification object:self.customDeviceData];
}

- (void)addIntegration:(NSString *)integration withDeviceToken:(NSData *)deviceToken {
	const unsigned *tokenBytes = [deviceToken bytes];
	NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
					   ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
					   ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
					   ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
	
	[[ATConnect sharedConnection] addIntegration:integration withConfiguration:@{@"token": token}];
}

- (void)removeIntegration:(NSString *)integration {
	[_integrationConfiguration removeObjectForKey:integration];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATConnectCustomDeviceDataChangedNotification object:self.customDeviceData];
}

#if TARGET_OS_IPHONE

- (BOOL)willShowInteractionForEvent:(NSString *)event {
	return [self canShowInteractionForEvent:event];
}

- (BOOL)canShowInteractionForEvent:(NSString *)event {
	return [[ATEngagementBackend sharedBackend] canShowInteractionForLocalEvent:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:customData withExtendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [[ATEngagementBackend sharedBackend] engageLocalEvent:event userInfo:nil customData:customData extendedData:extendedData fromViewController:viewController];
}

+ (NSDictionary *)extendedDataDate:(NSDate *)date {
	NSDictionary *time = @{@"time": @{@"version": @1,
									  @"timestamp": @([date timeIntervalSince1970])
									  }
						   };
	return time;
}

+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude {
	// Coordinates sent to server in order (longitude, latitude)
	NSDictionary *location = @{@"location": @{@"version": @1,
											  @"coordinates": @[@(longitude), @(latitude)]
											  }
							   };
	
	return location;
}


+ (NSDictionary *)extendedDataCommerceWithTransactionID:(NSString *)transactionID
											affiliation:(NSString *)affiliation
												revenue:(NSNumber *)revenue
											   shipping:(NSNumber *)shipping
													tax:(NSNumber *)tax
											   currency:(NSString *)currency
										  commerceItems:(NSArray *)commerceItems
{
	
	NSMutableDictionary *commerce = [NSMutableDictionary dictionary];
	commerce[@"version"] = @1;
	
	if (transactionID) {
		commerce[@"id"] = transactionID;
	}
	
	if (affiliation) {
		commerce[@"affiliation"] = affiliation;
	}
	
	if (revenue) {
		commerce[@"revenue"] = revenue;
	}
	
	if (shipping) {
		commerce[@"shipping"] = shipping;
	}
	
	if (tax) {
		commerce[@"tax"] = tax;
	}
	
	if (currency) {
		commerce[@"currency"] = currency;
	}
	
	if (commerceItems) {
		commerce[@"items"] = commerceItems;
	}
	
	return @{@"commerce": commerce};
}

+ (NSDictionary *)extendedDataCommerceItemWithItemID:(NSString *)itemID
												name:(NSString *)name
											category:(NSString *)category
											   price:(NSNumber *)price
											quantity:(NSNumber *)quantity
											currency:(NSString *)currency
{
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
	
	if (price) {
		commerceItem[@"price"] = price;
	}
	
	if (quantity) {
		commerceItem[@"quantity"] = quantity;
	}
	
	if (currency) {
		commerceItem[@"currency"] = currency;
	}
	
	return commerceItem;
}

- (BOOL)canShowMessageCenter {
	NSString *messageCenterCodePoint = [[ATInteraction apptentiveAppInteraction] codePointForEvent:ATEngagementMessageCenterEvent];
	return [[ATEngagementBackend sharedBackend] canShowInteractionForCodePoint:messageCenterCodePoint];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController {
	return [[ATBackend sharedBackend] presentMessageCenterFromViewController:viewController];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
	NSMutableDictionary *allowedCustomMessageData = [NSMutableDictionary dictionary];
	
	for (NSString *key in [customData allKeys]) {
		[self addCustomData:[customData objectForKey:key] withKey:key toCustomDataDictionary:allowedCustomMessageData];
	}
	
	return [[ATBackend sharedBackend] presentMessageCenterFromViewController:viewController withCustomData:allowedCustomMessageData];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController {
	return [self didReceiveRemoteNotification:userInfo fromViewController:viewController fetchCompletionHandler:nil];
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
					[[ATBackend sharedBackend] fetchMessagesInBackground:completionHandler];
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
					[[ATBackend sharedBackend] checkForMessages];
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
	[[ATEngagementBackend sharedBackend] resetUpgradeVersionInfo];
}

- (NSArray *)engagementInteractions {
	return [[ATEngagementBackend sharedBackend] allEngagementInteractions];
}

- (NSInteger)numberOfEngagementInteractions {
	return [[self engagementInteractions] count];
}

- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];
	
	return [interaction.configuration objectForKey:@"name"] ?: [interaction.configuration objectForKey:@"title"] ?: @"Untitled Interaction";
}

- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];
	
	return interaction.type;
}

- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController {
	[[ATEngagementBackend sharedBackend] presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[[ATBackend sharedBackend] dismissMessageCenterAnimated:animated completion:completion];
}

- (NSUInteger)unreadMessageCount {
	return [[ATBackend sharedBackend] unreadMessageCount];
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
	if (![[ATBackend sharedBackend] currentFeedback]) {
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
		[[ATBackend sharedBackend] setCurrentFeedback:feedback];
		[feedback release];
		feedback = nil;
	}
	
	if (!feedbackWindowController) {
		feedbackWindowController = [[ATFeedbackWindowController alloc] initWithFeedback:[[ATBackend sharedBackend] currentFeedback]];
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

- (void)showNotificationBannerForMessage:(ATAbstractMessage *)message {
	if ([ATBackend sharedBackend].notificationPopupsEnabled && [message isKindOfClass:[ATTextMessage class]]) {
		ATTextMessage *textMessage = (ATTextMessage *)message;
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
