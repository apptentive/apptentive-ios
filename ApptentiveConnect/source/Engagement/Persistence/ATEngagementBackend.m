//
//  ATEngagementBackend.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementBackend.h"
#import "ATBackend.h"
#import "ATEngagementGetManifestTask.h"
#import "ATTaskQueue.h"
#import "ATInteraction.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "ApptentiveMetrics.h"
#import "ATInteractionUpgradeMessageViewController.h"
#import "ATInteractionEnjoymentDialogController.h"
#import "ATInteractionRatingDialogController.h"
#import "ATInteractionFeedbackDialogController.h"
#import "ATInteractionMessageCenterController.h"
#import "ATInteractionAppStoreController.h"
#import "ATInteractionSurveyController.h"

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

NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

NSString *const ATEngagementCodePointHostAppVendorKey = @"local";
NSString *const ATEngagementCodePointHostAppInteractionKey = @"app";
NSString *const ATEngagementCodePointApptentiveVendorKey = @"com.apptentive";
NSString *const ATEngagementCodePointApptentiveAppInteractionKey = @"app";

@implementation ATEngagementBackend

+ (ATEngagementBackend *)sharedBackend {
	static ATEngagementBackend *sharedBackend = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedBackend = [[ATEngagementBackend alloc] init];
	});
	return sharedBackend;
}

- (id)init {
	if ((self = [super init])) {
		codePointInteractions = [[NSMutableDictionary alloc] init];
		
		NSDictionary *defaults = @{ATEngagementIsUpdateVersionKey: @NO,
								   ATEngagementIsUpdateBuildKey: @NO,
								   ATEngagementCodePointsInvokesTotalKey: @{},
								   ATEngagementCodePointsInvokesVersionKey: @{},
								   ATEngagementCodePointsInvokesLastDateKey: @{},
								   ATEngagementInteractionsInvokesTotalKey: @{},
								   ATEngagementInteractionsInvokesVersionKey: @{},
								   ATEngagementInteractionsInvokesLastDateKey: @{}};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		[self updateVersionInfo];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		if ([fm fileExistsAtPath:[ATEngagementBackend cachedEngagementStoragePath]]) {
			@try {
				NSDictionary *archivedInteractions = [NSKeyedUnarchiver unarchiveObjectWithFile:[ATEngagementBackend cachedEngagementStoragePath]];
				[codePointInteractions addEntriesFromDictionary:archivedInteractions];
			} @catch (NSException *exception) {
				ATLogError(@"Unable to unarchive engagement: %@", exception);
			}
		}
	}
	return self;
}

- (void)dealloc {
	[codePointInteractions release], codePointInteractions = nil;
	[super dealloc];
}

- (void)checkForEngagementManifest {
	if ([self shouldRetrieveNewEngagementManifest]) {
		ATEngagementGetManifestTask *task = [[ATEngagementGetManifestTask alloc] init];
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[task release], task = nil;
	}
}

- (BOOL)shouldRetrieveNewEngagementManifest {
	
	BOOL alwaysRetrieveManifest = NO;
#if APPTENTIVE_DEBUG
	alwaysRetrieveManifest = YES;
#endif
	if (alwaysRetrieveManifest) {
		return YES;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *expiration = [defaults objectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			NSFileManager *fm = [NSFileManager defaultManager];
			if (![fm fileExistsAtPath:[ATEngagementBackend cachedEngagementStoragePath]]) {
				// If no file, check anyway.
				return YES;
			}
			return NO;
		}
	} else {
		return YES;
	}
}

- (void)didReceiveNewCodePointInteractions:(NSDictionary *)receivedCodePointInteractions maxAge:(NSTimeInterval)expiresMaxAge {
	@synchronized(self) {
		[NSKeyedArchiver archiveRootObject:receivedCodePointInteractions toFile:[ATEngagementBackend cachedEngagementStoragePath]];
		// Store expiration.
		if (expiresMaxAge > 0) {
			NSDate *date = [NSDate dateWithTimeInterval:expiresMaxAge sinceDate:[NSDate date]];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:date forKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
		}
		
		[codePointInteractions removeAllObjects];
		[codePointInteractions addEntriesFromDictionary:receivedCodePointInteractions];
		
		[self updateVersionInfo];
	}
}

- (void)updateVersionInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *installDate = [defaults objectForKey:ATEngagementInstallDateKey];
	if (!installDate) {
		[defaults setObject:[NSDate date] forKey:ATEngagementInstallDateKey];
	}
	
	NSString *currentBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
	NSString *lastBundleVersion = [defaults objectForKey:ATEngagementLastUsedVersionKey];
	
	// Both version and build are required (by iTunes Connect) to be updated upon App Store release.
	// If the bundle version has changed, we can mark both version and build as updated.
	if (lastBundleVersion && ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[defaults setObject:@YES forKey:ATEngagementIsUpdateVersionKey];
		[defaults setObject:@YES forKey:ATEngagementIsUpdateBuildKey];
	}
	
	if (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[defaults setObject:currentBundleVersion forKey:ATEngagementLastUsedVersionKey];
		[defaults setObject:[NSDate date] forKey:ATEngagementUpgradeDateKey];
		[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
		[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesBuildKey];
		[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
		[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesBuildKey];
	}
}

+ (NSString *)cachedEngagementStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"cachedinteractions.objects"];
}

- (NSArray *)interactionsForCodePoint:(NSString *)codePoint {
	NSArray *interactions = [codePointInteractions objectForKey:codePoint];
	
	return interactions;
}

- (ATInteraction *)interactionForCodePoint:(NSString *)codePoint {
	NSArray *interactions = [self interactionsForCodePoint:codePoint];
	for (ATInteraction *interaction in interactions) {
		if ([interaction isValid]) {
			return interaction;
		}
	}
	
	return nil;
}

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string {
	// Only escape "%", "/", and "#".
	// Do not change unless the server spec changes.
	NSMutableString *escape = [string mutableCopy];
	[escape replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	
	return [escape autorelease];
}

- (BOOL)engageLocalEvent:(NSString *)eventLabel fromViewController:(UIViewController *)viewController {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:ATEngagementCodePointHostAppVendorKey fromInteraction:ATEngagementCodePointHostAppInteractionKey userInfo:nil fromViewController:viewController];
}

- (BOOL)engageLocalEvent:(NSString *)eventLabel userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:ATEngagementCodePointHostAppVendorKey fromInteraction:ATEngagementCodePointHostAppInteractionKey userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController];
}

- (BOOL)engageApptentiveAppEvent:(NSString *)eventLabel userInfo:(NSDictionary *)userInfo {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:ATEngagementCodePointApptentiveVendorKey fromInteraction:ATEngagementCodePointApptentiveAppInteractionKey userInfo:userInfo fromViewController:nil];
}

- (BOOL)engageApptentiveEvent:(NSString *)eventLabel fromInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:ATEngagementCodePointApptentiveVendorKey fromInteraction:interaction.type userInfo:nil fromViewController:viewController];
}

- (BOOL)engageApptentiveEvent:(NSString *)eventLabel fromInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:ATEngagementCodePointApptentiveVendorKey fromInteraction:interaction.type userInfo:userInfo fromViewController:viewController];
}

- (BOOL)engageEvent:(NSString *)eventLabel fromVendor:(NSString *)vendor fromInteraction:(NSString *)interaction userInfo:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController {
	return [[ATEngagementBackend sharedBackend] engageEvent:eventLabel fromVendor:vendor fromInteraction:interaction userInfo:userInfo customData:nil extendedData:nil fromViewController:viewController];
}

- (BOOL)engageEvent:(NSString *)eventLabel fromVendor:(NSString *)vendor fromInteraction:(NSString *)interaction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	NSString *encodedVendor = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:vendor];
	NSString *encodedInteraction = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:interaction];
	NSString *encodedEventLabel = [ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:eventLabel];
	
	NSString *codePoint = [NSString stringWithFormat:@"%@#%@#%@", encodedVendor, encodedInteraction, encodedEventLabel];

	return [[ATEngagementBackend sharedBackend] engage:codePoint userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController];
}

- (BOOL)engage:(NSString *)codePoint userInfo:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController {
	return [self engage:codePoint userInfo:userInfo customData:nil extendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)codePoint userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	ATLogInfo(@"Engage Apptentive event: %@", codePoint);
	
	[[ApptentiveMetrics sharedMetrics] addMetricWithName:codePoint info:userInfo customData:customData extendedData:extendedData];
	
	[self codePointWasEngaged:codePoint];
	BOOL didEngageInteraction = NO;
	
	NSArray *interactions = [codePointInteractions objectForKey:codePoint];
	ATLogInfo(@"%@", [NSString stringWithFormat:@"--Found %tu available interaction%@.", interactions.count, (interactions.count == 1) ? @"" : @"s"]);
	
	if (interactions.count > 0) {
		ATInteraction *interaction = [self interactionForCodePoint:codePoint];
		if (interaction) {
			ATLogInfo(@"--Running valid %@ interaction.", interaction.type, codePoint);
			ATLogInfo(@"");
			[self presentInteraction:interaction fromViewController:viewController];
			[self interactionWasEngaged:interaction];
			didEngageInteraction = YES;
			// Sync defaults so user doesn't see interaction more than once.
			[[NSUserDefaults standardUserDefaults] synchronize];
		} else {
			ATLogInfo(@"--Criteria not met for available interaction%@.", (interactions.count == 1) ? @"" : @"s");
			ATLogInfo(@"--There are no valid Apptentive interactions to run at this time.");
			ATLogInfo(@"");
		}
	}
	
	return didEngageInteraction;
}

- (void)codePointWasSeen:(NSString *)codePoint {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *invokesTotal = [defaults objectForKey:ATEngagementCodePointsInvokesTotalKey];
	if (![invokesTotal objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesTotalKey];
	}
	
	NSDictionary *invokesVersion = [defaults objectForKey:ATEngagementCodePointsInvokesVersionKey];
	if (![invokesVersion objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesVersionKey];
	}
	
	NSDictionary *invokesBuild = [defaults objectForKey:ATEngagementCodePointsInvokesBuildKey];
	if (![invokesBuild objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesBuildKey];
	}
	
	NSDictionary *invokesTimeAgo = [defaults objectForKey:ATEngagementCodePointsInvokesLastDateKey];
	if (![invokesTimeAgo objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesTimeAgo];
		[addedCodePoint setObject:[NSDate distantPast] forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesLastDateKey];
	}
}

- (void)codePointWasEngaged:(NSString *)codePoint {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSMutableDictionary *codePointsInvokesTotal = [[defaults objectForKey:ATEngagementCodePointsInvokesTotalKey] mutableCopy];
	NSNumber *codePointInvokesTotal = [codePointsInvokesTotal objectForKey:codePoint] ?: @0;
	codePointInvokesTotal = @(codePointInvokesTotal.intValue + 1);
	[codePointsInvokesTotal setObject:codePointInvokesTotal forKey:codePoint];
	[defaults setObject:codePointsInvokesTotal forKey:ATEngagementCodePointsInvokesTotalKey];
	[codePointsInvokesTotal release];
	
	NSMutableDictionary *codePointsInvokesVersion = [[defaults objectForKey:ATEngagementCodePointsInvokesVersionKey] mutableCopy];
	NSNumber *codePointInvokesVersion = [codePointsInvokesVersion objectForKey:codePoint] ?: @0;
	codePointInvokesVersion = @(codePointInvokesVersion.intValue + 1);
	[codePointsInvokesVersion setObject:codePointInvokesVersion forKey:codePoint];
	[defaults setObject:codePointsInvokesVersion forKey:ATEngagementCodePointsInvokesVersionKey];
	[codePointsInvokesVersion release];
	
	NSMutableDictionary *codePointsInvokesBuild = [[defaults objectForKey:ATEngagementCodePointsInvokesBuildKey] mutableCopy];
	NSNumber *codePointInvokesBuild = [codePointsInvokesBuild objectForKey:codePoint] ?: @0;
	codePointInvokesBuild = @(codePointInvokesBuild.intValue + 1);
	[codePointsInvokesBuild setObject:codePointInvokesBuild forKey:codePoint];
	[defaults setObject:codePointsInvokesBuild forKey:ATEngagementCodePointsInvokesBuildKey];
	[codePointsInvokesBuild release];
	
	NSMutableDictionary *codePointsInvokesTimeAgo = [[defaults objectForKey:ATEngagementCodePointsInvokesLastDateKey] mutableCopy];
	[codePointsInvokesTimeAgo setObject:[NSDate date] forKey:codePoint];
	[defaults setObject:codePointsInvokesTimeAgo forKey:ATEngagementCodePointsInvokesLastDateKey];
	[codePointsInvokesTimeAgo release];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *invokesTotal = [defaults objectForKey:ATEngagementInteractionsInvokesTotalKey];
	if (![invokesTotal objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesTotalKey];
	}
	
	NSDictionary *invokesVersion = [defaults objectForKey:ATEngagementInteractionsInvokesVersionKey];
	if (![invokesVersion objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesVersionKey];
	}
	
	NSDictionary *invokesBuild = [defaults objectForKey:ATEngagementInteractionsInvokesBuildKey];
	if (![invokesBuild objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesBuildKey];
	}
	
	NSDictionary *invokesLastDate = [defaults objectForKey:ATEngagementInteractionsInvokesLastDateKey];
	if (![invokesLastDate objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesLastDate];
		[addedInteraction setObject:[NSDate distantPast] forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesLastDateKey];
	}
}

- (void)interactionWasEngaged:(ATInteraction *)interaction {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSMutableDictionary *interactionsInvokesTotal = [[defaults objectForKey:ATEngagementInteractionsInvokesTotalKey] mutableCopy];
	NSNumber *interactionInvokesTotal = [interactionsInvokesTotal objectForKey:interaction.identifier] ?: @0;
	interactionInvokesTotal = @(interactionInvokesTotal.intValue + 1);
	[interactionsInvokesTotal setObject:interactionInvokesTotal forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesTotal forKey:ATEngagementInteractionsInvokesTotalKey];
	[interactionsInvokesTotal release];
	
	NSMutableDictionary *interactionsInvokesVersion = [[defaults objectForKey:ATEngagementInteractionsInvokesVersionKey] mutableCopy];
	NSNumber *interactionInvokesVersion = [interactionsInvokesVersion objectForKey:interaction.identifier] ?: @0;
	interactionInvokesVersion = @(interactionInvokesVersion.intValue +1);
	[interactionsInvokesVersion setObject:interactionInvokesVersion forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesVersion forKey:ATEngagementInteractionsInvokesVersionKey];
	[interactionsInvokesVersion release];
	
	NSMutableDictionary *interactionsInvokesBuild = [[defaults objectForKey:ATEngagementInteractionsInvokesBuildKey] mutableCopy];
	NSNumber *interactionInvokesBuild = [interactionsInvokesBuild objectForKey:interaction.identifier] ?: @0;
	interactionInvokesBuild = @(interactionInvokesBuild.intValue +1);
	[interactionsInvokesBuild setObject:interactionInvokesBuild forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesBuild forKey:ATEngagementInteractionsInvokesBuildKey];
	[interactionsInvokesBuild release];
	
	NSMutableDictionary *interactionsInvokesLastDate = [[defaults objectForKey:ATEngagementInteractionsInvokesLastDateKey] mutableCopy];
	[interactionsInvokesLastDate setObject:[NSDate date] forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesLastDate forKey:ATEngagementInteractionsInvokesLastDateKey];
	[interactionsInvokesLastDate release];
}

- (void)presentInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
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
		case ATInteractionTypeFeedbackDialog:
			[self presentFeedbackDialogInteraction:interaction fromViewController:viewController];
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
		case ATInteractionTypeUnknown:
		default:
			ATLogError(@"Attempting to present an unknown interaction type!");
			break;
	}
}

- (void)presentUpgradeMessageInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"UpgradeMessage"], @"Attempted to present an UpgradeMessage interaction with an interaction of type: %@", interaction.type);
	if (![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		// Don't show upgrade messages on anything except iOS 7 and above.
		return;
	}
	
	ATInteractionUpgradeMessageViewController *upgradeMessage = [[ATInteractionUpgradeMessageViewController alloc] initWithInteraction:interaction];
	[upgradeMessage presentFromViewController:viewController animated:YES];
	[upgradeMessage release];
}

- (void)presentEnjoymentDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to present an EnjoymentDialog interaction with an interaction of type: %@", interaction.type);

	ATInteractionEnjoymentDialogController *enjoymentDialog = [[ATInteractionEnjoymentDialogController alloc] initWithInteraction:interaction];
	[enjoymentDialog showEnjoymentDialogFromViewController:viewController];
	
	[enjoymentDialog release];
}

- (void)presentRatingDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"RatingDialog"], @"Attempted to present a RatingDialog interaction with an interaction of type: %@", interaction.type);
	
	ATInteractionRatingDialogController *ratingDialog = [[ATInteractionRatingDialogController alloc] initWithInteraction:interaction];
	[ratingDialog showRatingDialogFromViewController:viewController];
	
	[ratingDialog release];
}

- (void)presentFeedbackDialogInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"FeedbackDialog"], @"Attempted to present a FeedbackDialog interaction with an interaction of type: %@", interaction.type);
	
	ATInteractionFeedbackDialogController *feedbackDialog = [[ATInteractionFeedbackDialogController alloc] initWithInteraction:interaction];
	[feedbackDialog showFeedbackDialogFromViewController:viewController];
	
	[feedbackDialog release];
}

- (void)presentMessageCenterInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to present a MessageCenter interaction with an interaction of type: %@", interaction.type);
	
	ATInteractionMessageCenterController *messageCenter = [[ATInteractionMessageCenterController alloc] initWithInteraction:interaction];
	[messageCenter showMessageCenterFromViewController:viewController];
	
	[messageCenter release];
}

- (void)presentAppStoreRatingInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"AppStoreRating"], @"Attempted to present an App Store Rating interaction with an interaction of type: %@", interaction.type);
	
	ATInteractionAppStoreController *appStore = [[ATInteractionAppStoreController alloc] initWithInteraction:interaction];
	[appStore openAppStoreFromViewController:viewController];
	
	[appStore release];
}

- (void)presentSurveyInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	NSAssert([interaction.type isEqualToString:@"Survey"], @"Attempted to present a Survey interaction with an interaction of type: %@", interaction.type);
	
	ATInteractionSurveyController *survey = [[ATInteractionSurveyController alloc] initWithInteraction:interaction];
	[survey showSurveyFromViewController:viewController];
	
	[survey release];
}

- (void)resetUpgradeVersionInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:ATEngagementLastUsedVersionKey];
	[defaults removeObjectForKey:ATEngagementUpgradeDateKey];
	[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
	[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
	[defaults synchronize];
}
@end
