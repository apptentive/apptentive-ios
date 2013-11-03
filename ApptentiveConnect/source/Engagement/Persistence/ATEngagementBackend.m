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
#import "ATAppRatingFlow_Private.h"
#import "ATConnect_Private.h"
#import "ATInteractionUpgradeMessageViewController.h"
#import "ATUtilities.h"

NSString *const ATEngagementInstallDateKey = @"ATEngagementInstallDateKey";
NSString *const ATEngagementUpgradeDateKey = @"ATEngagementUpgradeDateKey";
NSString *const ATEngagementLastUsedVersionKey = @"ATEngagementLastUsedVersionKey";
NSString *const ATEngagementCodePointsInvokesTotalKey = @"ATEngagementCodePointsInvokesTotalKey";
NSString *const ATEngagementCodePointsInvokesVersionKey = @"ATEngagementCodePointsInvokesVersionKey";
NSString *const ATEngagementInteractionsInvokesTotalKey = @"ATEngagementInteractionsInvokesTotalKey";
NSString *const ATEngagementInteractionsInvokesVersionKey = @"ATEngagementInteractionsInvokesVersionKey";

NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

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
		
		NSDictionary *defaults = @{ATEngagementCodePointsInvokesTotalKey : @{},
							 ATEngagementCodePointsInvokesVersionKey : @{},
							 ATEngagementInteractionsInvokesTotalKey : @{},
							 ATEngagementInteractionsInvokesVersionKey : @{}};
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
			[defaults synchronize];
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
	
	if (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[defaults setObject:currentBundleVersion forKey:ATEngagementLastUsedVersionKey];
		[defaults setObject:[NSDate date] forKey:ATEngagementUpgradeDateKey];
		[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
		[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
	}
	
	[defaults synchronize];
}

+ (NSString *)cachedEngagementStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"cachedinteractions.objects"];
}

- (NSArray *)interactionsForCodePoint:(NSString *)codePoint {
	NSArray *interactions = [codePointInteractions objectForKey:codePoint];
	ATLogInfo(@"Found %lu cached interactions for code point: %@", interactions.count, codePoint);
	
	return interactions;
}

- (ATInteraction *)interactionForCodePoint:(NSString *)codePoint {
	NSArray *interactions = [self interactionsForCodePoint:codePoint];
	for (ATInteraction *interaction in interactions) {
		if ([interaction criteriaAreMet]) {
			ATLogInfo(@"Found valid %@ interaction for code point: %@", interaction.type, codePoint);
			return interaction;
		}
	}
	
	ATLogInfo(@"No valid Apptentive interactions found for code point: %@", codePoint);
	return nil;
}

- (void)engage:(NSString *)codePoint fromViewController:(UIViewController *)viewController {
	[self codePointWasEngaged:codePoint];
	
	ATInteraction *interaction = [self interactionForCodePoint:codePoint];
	if (interaction) {
		[self presentInteraction:interaction fromViewController:viewController];
		[self interactionWasEngaged:interaction];
	}
}

- (void)codePointWasSeen:(NSString *)codePoint {
	NSDictionary *invokesTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesTotalKey];
	if (![invokesTotal objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[[NSUserDefaults standardUserDefaults] setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesTotalKey];
	}
	
	NSDictionary *invokesVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesVersionKey];
	if (![invokesVersion objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[[NSUserDefaults standardUserDefaults] setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesVersionKey];
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
	
	[defaults synchronize];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	NSDictionary *invokesTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesTotalKey];
	if (![invokesTotal objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedInteraction setObject:@0 forKey:interactionID];
		[[NSUserDefaults standardUserDefaults] setObject:addedInteraction forKey:ATEngagementInteractionsInvokesTotalKey];
	}
	
	NSDictionary *invokesVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesVersionKey];
	if (![invokesVersion objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedInteraction setObject:@0 forKey:interactionID];
		[[NSUserDefaults standardUserDefaults] setObject:addedInteraction forKey:ATEngagementInteractionsInvokesVersionKey];
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
	
	[defaults synchronize];
}

- (void)presentInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	if ([interaction.type isEqualToString:@"UpgradeMessage"]) {
		[self presentUpgradeMessageInteraction:interaction fromViewController:viewController];
	} else if ([interaction.type isEqualToString:@"EnjoymentDialog"]) {
		[self presentEnjoymentDialogInteraction:interaction fromViewController:viewController];
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
	ATLogError(@"Need to present an EnjoymentDialog here!");
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
