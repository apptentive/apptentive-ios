//
//  ATEngagementBackend.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementBackend.h"
#import "ATBackend.h"
#import "ATTaskQueue.h"
#import "ATInteraction.h"
#import "ATInteractionInvocation.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "ApptentiveMetrics.h"
#import "ATInteractionUpgradeMessageViewController.h"
#import "ATInteractionEnjoymentDialogController.h"
#import "ATInteractionRatingDialogController.h"
#import "ATInteractionMessageCenterController.h"
#import "ATInteractionAppStoreController.h"
#import "ATInteractionSurveyController.h"
#import "ATInteractionTextModalController.h"
#import "ATInteractionNavigateToLink.h"
#import "ATInteractionUsageData.h"
#import "ATEngagementManifest.h"

NSString *const ATEngagementInstallDateKey = @"ATEngagementInstallDateKey";
NSString *const ATEngagementUpgradeDateKey = @"ATEngagementUpgradeDateKey";
NSString *const ATEngagementLastUsedVersionKey = @"ATEngagementLastUsedVersionKey";
NSString *const ATEngagementIsUpdateVersionKey = @"ATEngagementIsUpdateVersionKey";
NSString *const ATEngagementIsUpdateBuildKey = @"ATEngagementIsUpdateBuildKey";
NSString *const ATEngagementCodePointsInvokesTotalKey = @"ATEngagementCodePointsInvokesTotalKey";
NSString *const ATEngagementCodePointsInvokesVersionKey = @"ATEngagementCodePointsInvokesVersionKey";
NSString *const ATEngagementCodePointsInvokesBuildKey = @"ATEngagementCodePointsInvokesBuildKey";
NSString *const ATEngagementCodePointsInvokesLastDateKey = @"ATEngagementCodePointsInvokesLastDateKey";
NSString *const ATEngagementInteractionsInvokesTotalKey = @"ATEngagementInteractionsInvokesTotalKey";
NSString *const ATEngagementInteractionsInvokesVersionKey = @"ATEngagementInteractionsInvokesVersionKey";
NSString *const ATEngagementInteractionsInvokesLastDateKey = @"ATEngagementInteractionsInvokesLastDateKey";
NSString *const ATEngagementInteractionsInvokesBuildKey = @"ATEngagementInteractionsInvokesBuildKey";
NSString *const ATEngagementInteractionsSDKVersionKey = @"ATEngagementInteractionsSDKVersionKey";

NSString *const ATEngagementCodePointHostAppVendorKey = @"local";
NSString *const ATEngagementCodePointHostAppInteractionKey = @"app";
NSString *const ATEngagementCodePointApptentiveVendorKey = @"com.apptentive";
NSString *const ATEngagementCodePointApptentiveAppInteractionKey = @"app";

NSString *const ATEngagementMessageCenterEvent = @"show_message_center";

NSString *const ATEngagementApplicationVersionKey = @"ATEngagementApplicationVersionKey";
NSString *const ATEngagementApplicationBuildKey = @"ATEngagementApplicationBuildKey";

NSString *const ATEngagementSDKVersionKey = @"ATEngagementSDKVersionKey";
NSString *const ATEngagementSDKDistributionNameKey = @"ATEngagementSDKDistributionNameKey";
NSString *const ATEngagementSDKDistributionVersionKey = @"ATEngagementSDKDistributionVersionKey";


@interface ATEngagementBackend ()

@property (strong, nonatomic) ATEngagementManifestUpdater *manifestUpdater;

@end

@implementation ATEngagementBackend

- (id)initWithStoragePath:(NSString *)storagePath {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		self.manifestUpdater = [[ATEngagementManifestUpdater alloc] init];
		self.manifestUpdater.delegate = self;

		_engagementData = [self emptyEngagementData];
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.engagementDataStoragePath]) {
			@try {
				NSDictionary *archivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:self.engagementDataStoragePath];
				[_engagementData addEntriesFromDictionary:archivedData];
			} @catch (NSException *exception) {
				ATLogError(@"Unable to unarchive engagement data: %@", exception);
			}
		} else if ([[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey]) {
			NSArray *keys = @[
							  ATEngagementInstallDateKey,
							  ATEngagementUpgradeDateKey,
							  ATEngagementLastUsedVersionKey,
							  ATEngagementIsUpdateVersionKey,
							  ATEngagementIsUpdateBuildKey,
							  ATEngagementCodePointsInvokesTotalKey,
							  ATEngagementCodePointsInvokesVersionKey,
							  ATEngagementCodePointsInvokesBuildKey,
							  ATEngagementCodePointsInvokesLastDateKey,
							  ATEngagementInteractionsInvokesTotalKey,
							  ATEngagementInteractionsInvokesVersionKey,
							  ATEngagementInteractionsInvokesBuildKey,
							  ATEngagementInteractionsInvokesLastDateKey,
							  ATEngagementInteractionsSDKVersionKey
							  ];

			for (NSString *key in keys) {
				NSObject *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
				_engagementData[key] = value;
			}

			@try {
				[NSKeyedArchiver archiveRootObject:_engagementData toFile:self.engagementDataStoragePath];
				for (NSString *key in keys) {
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
				}
			} @catch (NSException *exception) {
				ATLogError(@"Unable to save migrated engagement data: %@", exception);
			}
		}

		[self updateVersionInfo];

		_usageData = [[ATInteractionUsageData alloc] initWithEngagementData:self.engagementData];
	}

	return self;
}

- (NSMutableDictionary *)emptyEngagementData {
	return [@{
			 ATEngagementIsUpdateVersionKey: @NO,
			 ATEngagementIsUpdateBuildKey: @NO,
			 ATEngagementCodePointsInvokesTotalKey: @{},
			 ATEngagementCodePointsInvokesVersionKey: @{},
			 ATEngagementCodePointsInvokesBuildKey: @{},
			 ATEngagementCodePointsInvokesLastDateKey: @{},
			 ATEngagementInteractionsInvokesTotalKey: @{},
			 ATEngagementInteractionsInvokesVersionKey: @{},
			 ATEngagementInteractionsInvokesBuildKey: @{},
			 ATEngagementInteractionsInvokesLastDateKey: @{}
			 } mutableCopy];
}

- (void)resetEngagementData {
	_engagementData = [self emptyEngagementData];
	[self.engagementData removeObjectForKey:ATEngagementInstallDateKey];
	[self.engagementData removeObjectForKey:ATEngagementLastUsedVersionKey];

	[self updateVersionInfo];

	_usageData = [[ATInteractionUsageData alloc] initWithEngagementData:self.engagementData];
}

- (void)checkForEngagementManifest {
	if (self.manifestUpdater.needsUpdate) {
		[self.manifestUpdater update];
	}
}

- (void)updater:(ATUpdater *)updater didFinish:(BOOL)success {
	if (success) {
		[self updateVersionInfo];
	}
}

- (void)updateVersionInfo {
	NSDate *installDate = [self.engagementData objectForKey:ATEngagementInstallDateKey];
	if (!installDate) {
		[self.engagementData setObject:[NSDate date] forKey:ATEngagementInstallDateKey];
	}

	NSString *currentBundleVersion = [ATUtilities appBundleVersionString];
	NSString *lastBundleVersion = [self.engagementData objectForKey:ATEngagementLastUsedVersionKey];

	// Both version and build are required (by iTunes Connect) to be updated upon App Store release.
	// If the bundle version has changed, we can mark both version and build as updated.
	if (lastBundleVersion && ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[self.engagementData setObject:@YES forKey:ATEngagementIsUpdateVersionKey];
		[self.engagementData setObject:@YES forKey:ATEngagementIsUpdateBuildKey];
	}

	if (currentBundleVersion && (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion])) {
		[self.engagementData setObject:currentBundleVersion forKey:ATEngagementLastUsedVersionKey];
		[self.engagementData setObject:[NSDate date] forKey:ATEngagementUpgradeDateKey];
		[self.engagementData setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
		[self.engagementData setObject:@{} forKey:ATEngagementCodePointsInvokesBuildKey];
		[self.engagementData setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
		[self.engagementData setObject:@{} forKey:ATEngagementInteractionsInvokesBuildKey];
	}

	NSString *buildNumberString = [ATUtilities buildNumberString] ?: @"";
	[self.engagementData setObject:buildNumberString forKey:ATEngagementApplicationBuildKey];

	NSString *versionString = [ATUtilities appVersionString] ?: @"";
	[self.engagementData setObject:versionString forKey:ATEngagementApplicationVersionKey];

	NSString *SDKVersion = kATConnectVersionString;
	[self.engagementData setObject:SDKVersion forKey:ATEngagementSDKVersionKey];

	NSString *SDKDistribution = [ATConnect sharedConnection].backend.distributionName ?: @"";
	[self.engagementData setObject:SDKDistribution forKey:ATEngagementSDKDistributionNameKey];

	NSString *SDKDistributionVersion = [ATConnect sharedConnection].backend.distributionVersion ?: @"";
	[self.engagementData setObject:SDKDistributionVersion forKey:ATEngagementSDKDistributionVersionKey];
}

- (NSString *)engagementDataStoragePath {
	return [self.storagePath stringByAppendingPathComponent:@"engagementData.objects"];
}

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event {
	NSString *codePoint = [[ATInteraction localAppInteraction] codePointForEvent:event];

	return [self canShowInteractionForCodePoint:codePoint];
}

- (BOOL)canShowInteractionForCodePoint:(NSString *)codePoint {
	ATInteraction *interaction = [[ATConnect sharedConnection].engagementBackend interactionForEvent:codePoint];

	return (interaction != nil);
}

- (ATInteraction *)interactionForInvocations:(NSArray *)invocations {
	NSString *interactionID = nil;

	for (NSObject *invocationOrDictionary in invocations) {
		ATInteractionInvocation *invocation = nil;

		// Allow parsing of ATInteractionInvocation and NSDictionary invocation objects
		if ([invocationOrDictionary isKindOfClass:[ATInteractionInvocation class]]) {
			invocation = (ATInteractionInvocation *)invocationOrDictionary;
		} else if ([invocationOrDictionary isKindOfClass:[NSDictionary class]]) {
			invocation = [ATInteractionInvocation invocationWithJSONDictionary:((NSDictionary *)invocationOrDictionary)];
		} else {
			ATLogError(@"Attempting to parse an invocation that is neither an ATInteractionInvocation or NSDictionary.");
		}

		if (invocation && [invocation isKindOfClass:[ATInteractionInvocation class]]) {
			if ([invocation isValid]) {
				interactionID = invocation.interactionID;
				break;
			}
		}
	}

	ATInteraction *interaction = nil;
	if (interactionID) {
		interaction = self.manifestUpdater.interactions[interactionID];
	}

	return interaction;
}

- (ATInteraction *)interactionForEvent:(NSString *)event {
	NSArray *invocations = self.manifestUpdater.targets[event];
	ATInteraction *interaction = [self interactionForInvocations:invocations];

	return interaction;
}

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string {
	// Only escape "%", "/", and "#".
	// Do not change unless the server spec changes.
	NSMutableString *escape = [string mutableCopy];
	[escape replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];

	return escape;
}

+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event {
	NSString *encodedVendor = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:vendor];
	NSString *encodedInteractionType = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:interactionType];
	NSString *encodedEvent = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:event];

	NSString *codePoint = [NSString stringWithFormat:@"%@#%@#%@", encodedVendor, encodedInteractionType, encodedEvent];

	return codePoint;
}

- (BOOL)engageApptentiveAppEvent:(NSString *)event {
	return [[ATInteraction apptentiveAppInteraction] engage:event fromViewController:nil];
}

- (BOOL)engageLocalEvent:(NSString *)event userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [[ATInteraction localAppInteraction] engage:event fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData];
}

- (BOOL)engageCodePoint:(NSString *)codePoint fromInteraction:(ATInteraction *)fromInteraction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	ATLogInfo(@"Engage Apptentive event: %@", codePoint);
	if (![[ATConnect sharedConnection].backend isReady]) {
		return NO;
	}

	[[ApptentiveMetrics sharedMetrics] addMetricWithName:codePoint fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];

	[self codePointWasEngaged:codePoint];

	BOOL didEngageInteraction = NO;

	ATInteraction *interaction = [self interactionForEvent:codePoint];
	if (interaction) {
		ATLogInfo(@"--Running valid %@ interaction.", interaction.type);
		[self presentInteraction:interaction fromViewController:viewController];

		[self interactionWasEngaged:interaction];
		didEngageInteraction = YES;

		[self save];
	}

	return didEngageInteraction;
}

- (void)keyPathWasSeen:(NSString *)keyPath {
	/*
	 Record the keyPath if needed, to later be used in predicate evaluation.
	 */

	if ([keyPath hasPrefix:@"code_point/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *codePoint = [components objectAtIndex:1];
			[[ATConnect sharedConnection].engagementBackend codePointWasSeen:codePoint];
		}
	} else if ([keyPath hasPrefix:@"interactions/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *interactionID = [components objectAtIndex:1];
			[[ATConnect sharedConnection].engagementBackend interactionWasSeen:interactionID];
		}
	}
}

- (void)codePointWasSeen:(NSString *)codePoint {
	NSDictionary *invokesTotal = [self.engagementData objectForKey:ATEngagementCodePointsInvokesTotalKey];
	if (![invokesTotal objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[self.engagementData setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesTotalKey];
	}

	NSDictionary *invokesVersion = [self.engagementData objectForKey:ATEngagementCodePointsInvokesVersionKey];
	if (![invokesVersion objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[self.engagementData setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesVersionKey];
	}

	NSDictionary *invokesBuild = [self.engagementData objectForKey:ATEngagementCodePointsInvokesBuildKey];
	if (![invokesBuild objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[self.engagementData setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesBuildKey];
	}

	[self save];
}

- (void)codePointWasEngaged:(NSString *)codePoint {
	NSMutableDictionary *codePointsInvokesTotal = [[self.engagementData objectForKey:ATEngagementCodePointsInvokesTotalKey] mutableCopy];
	NSNumber *codePointInvokesTotal = [codePointsInvokesTotal objectForKey:codePoint] ?: @0;
	codePointInvokesTotal = @(codePointInvokesTotal.intValue + 1);
	[codePointsInvokesTotal setObject:codePointInvokesTotal forKey:codePoint];
	[self.engagementData setObject:codePointsInvokesTotal forKey:ATEngagementCodePointsInvokesTotalKey];

	NSMutableDictionary *codePointsInvokesVersion = [[self.engagementData objectForKey:ATEngagementCodePointsInvokesVersionKey] mutableCopy];
	NSNumber *codePointInvokesVersion = [codePointsInvokesVersion objectForKey:codePoint] ?: @0;
	codePointInvokesVersion = @(codePointInvokesVersion.intValue + 1);
	[codePointsInvokesVersion setObject:codePointInvokesVersion forKey:codePoint];
	[self.engagementData setObject:codePointsInvokesVersion forKey:ATEngagementCodePointsInvokesVersionKey];

	NSMutableDictionary *codePointsInvokesBuild = [[self.engagementData objectForKey:ATEngagementCodePointsInvokesBuildKey] mutableCopy];
	NSNumber *codePointInvokesBuild = [codePointsInvokesBuild objectForKey:codePoint] ?: @0;
	codePointInvokesBuild = @(codePointInvokesBuild.intValue + 1);
	[codePointsInvokesBuild setObject:codePointInvokesBuild forKey:codePoint];
	[self.engagementData setObject:codePointsInvokesBuild forKey:ATEngagementCodePointsInvokesBuildKey];

	NSMutableDictionary *codePointsInvokesTimeAgo = [[self.engagementData objectForKey:ATEngagementCodePointsInvokesLastDateKey] mutableCopy];
	[codePointsInvokesTimeAgo setObject:[NSDate date] forKey:codePoint];
	[self.engagementData setObject:codePointsInvokesTimeAgo forKey:ATEngagementCodePointsInvokesLastDateKey];

	[self save];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	NSDictionary *invokesTotal = [self.engagementData objectForKey:ATEngagementInteractionsInvokesTotalKey];
	if (![invokesTotal objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedInteraction setObject:@0 forKey:interactionID];
		[self.engagementData setObject:addedInteraction forKey:ATEngagementInteractionsInvokesTotalKey];
	}

	NSDictionary *invokesVersion = [self.engagementData objectForKey:ATEngagementInteractionsInvokesVersionKey];
	if (![invokesVersion objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedInteraction setObject:@0 forKey:interactionID];
		[self.engagementData setObject:addedInteraction forKey:ATEngagementInteractionsInvokesVersionKey];
	}

	NSDictionary *invokesBuild = [self.engagementData objectForKey:ATEngagementInteractionsInvokesBuildKey];
	if (![invokesBuild objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedInteraction setObject:@0 forKey:interactionID];
		[self.engagementData setObject:addedInteraction forKey:ATEngagementInteractionsInvokesBuildKey];
	}

	[self save];
}

- (void)interactionWasEngaged:(ATInteraction *)interaction {
	NSMutableDictionary *interactionsInvokesTotal = [[self.engagementData objectForKey:ATEngagementInteractionsInvokesTotalKey] mutableCopy];
	NSNumber *interactionInvokesTotal = [interactionsInvokesTotal objectForKey:interaction.identifier] ?: @0;
	interactionInvokesTotal = @(interactionInvokesTotal.intValue + 1);
	[interactionsInvokesTotal setObject:interactionInvokesTotal forKey:interaction.identifier];
	[self.engagementData setObject:interactionsInvokesTotal forKey:ATEngagementInteractionsInvokesTotalKey];

	NSMutableDictionary *interactionsInvokesVersion = [[self.engagementData objectForKey:ATEngagementInteractionsInvokesVersionKey] mutableCopy];
	NSNumber *interactionInvokesVersion = [interactionsInvokesVersion objectForKey:interaction.identifier] ?: @0;
	interactionInvokesVersion = @(interactionInvokesVersion.intValue + 1);
	[interactionsInvokesVersion setObject:interactionInvokesVersion forKey:interaction.identifier];
	[self.engagementData setObject:interactionsInvokesVersion forKey:ATEngagementInteractionsInvokesVersionKey];

	NSMutableDictionary *interactionsInvokesBuild = [[self.engagementData objectForKey:ATEngagementInteractionsInvokesBuildKey] mutableCopy];
	NSNumber *interactionInvokesBuild = [interactionsInvokesBuild objectForKey:interaction.identifier] ?: @0;
	interactionInvokesBuild = @(interactionInvokesBuild.intValue + 1);
	[interactionsInvokesBuild setObject:interactionInvokesBuild forKey:interaction.identifier];
	[self.engagementData setObject:interactionsInvokesBuild forKey:ATEngagementInteractionsInvokesBuildKey];

	NSMutableDictionary *interactionsInvokesLastDate = [[self.engagementData objectForKey:ATEngagementInteractionsInvokesLastDateKey] mutableCopy];
	[interactionsInvokesLastDate setObject:[NSDate date] forKey:interaction.identifier];
	[self.engagementData setObject:interactionsInvokesLastDate forKey:ATEngagementInteractionsInvokesLastDateKey];

	[self save];
}

- (void)presentInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	if (!interaction) {
		ATLogError(@"Attempting to present an interaction that does not exist!");
		return;
	}

	if (![[NSThread currentThread] isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self presentInteraction:interaction fromViewController:viewController];
		});
		return;
	}

	if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
		// Only present interaction UI in Active state.
		return;
	}

	switch (interaction.interactionType) {
		case ATInteractionTypeUpgradeMessage:
			[self presentUpgradeMessageInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeEnjoymentDialog:
			[self presentEnjoymentDialogInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeRatingDialog:
			[self presentRatingDialogInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeMessageCenter:
			[self presentMessageCenterInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeAppStoreRating:
			[self presentAppStoreRatingInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeSurvey:
			[self presentSurveyInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeTextModal:
			[self presentTextModalInteraction:interaction fromViewController:viewController];
			break;
		case ATInteractionTypeNavigateToLink:
			[self presentNavigateToLinkInteraction:interaction];
			break;
		case ATInteractionTypeUnknown:
		default:
			ATLogError(@"Attempting to present an unknown interaction type!");
			break;
	}
}

- (void)presentUpgradeMessageInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"UpgradeMessage"], @"Attempted to present an UpgradeMessage interaction with an interaction of type: %@", interaction.type);

	ATInteractionUpgradeMessageViewController *upgradeMessage = [ATInteractionUpgradeMessageViewController interactionUpgradeMessageViewControllerWithInteraction:interaction];
	[upgradeMessage presentFromViewController:viewController animated:YES];
}

- (void)presentEnjoymentDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to present an EnjoymentDialog interaction with an interaction of type: %@", interaction.type);

	ATInteractionEnjoymentDialogController *enjoymentDialog = [[ATInteractionEnjoymentDialogController alloc] initWithInteraction:interaction];
	[enjoymentDialog presentEnjoymentDialogFromViewController:viewController];
}

- (void)presentRatingDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"RatingDialog"], @"Attempted to present a RatingDialog interaction with an interaction of type: %@", interaction.type);

	ATInteractionRatingDialogController *ratingDialog = [[ATInteractionRatingDialogController alloc] initWithInteraction:interaction];
	[ratingDialog presentRatingDialogFromViewController:viewController];
}

- (void)presentMessageCenterInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to present a MessageCenter interaction with an interaction of type: %@", interaction.type);

	ATInteractionMessageCenterController *messageCenter = [[ATInteractionMessageCenterController alloc] initWithInteraction:interaction];
	[messageCenter showMessageCenterFromViewController:viewController];
}

- (void)presentAppStoreRatingInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"AppStoreRating"], @"Attempted to present an App Store Rating interaction with an interaction of type: %@", interaction.type);

	ATInteractionAppStoreController *appStore = [[ATInteractionAppStoreController alloc] initWithInteraction:interaction];
	[appStore openAppStoreFromViewController:viewController];
}

- (void)presentSurveyInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"Survey"], @"Attempted to present a Survey interaction with an interaction of type: %@", interaction.type);

	ATInteractionSurveyController *survey = [[ATInteractionSurveyController alloc] initWithInteraction:interaction];
	[survey showSurveyFromViewController:viewController];
}

- (void)presentTextModalInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"TextModal"], @"Attempted to present a Text Modal interaction with an interaction of type: %@", interaction.type);

	ATInteractionTextModalController *textModal = [[ATInteractionTextModalController alloc] initWithInteraction:interaction];
	[textModal presentTextModalAlertFromViewController:viewController];
}


- (void)presentNavigateToLinkInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"NavigateToLink"], @"Attempted to present a NavigateToLink interaction with an interaction of type: %@", interaction.type);

	[ATInteractionNavigateToLink navigateToLinkWithInteraction:interaction];
}

- (void)resetUpgradeVersionInfo {
	[self.engagementData removeObjectForKey:ATEngagementLastUsedVersionKey];
	[self.engagementData removeObjectForKey:ATEngagementUpgradeDateKey];
	[self.engagementData setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
	[self.engagementData setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];

	[self save];
}

- (NSArray *)allEngagementInteractions {
	return [self.manifestUpdater.interactions allValues];
}

- (void)save {
	[NSKeyedArchiver archiveRootObject:self.engagementData toFile:self.engagementDataStoragePath];
}

@end
