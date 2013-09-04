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

NSString *const ATEngagementInstallDateKey = @"ATEngagementInstallDateKey";
NSString *const ATEngagementUpgradeDateKey = @"ATEngagementUpgradeDateKey";
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
	}
}

+ (NSString *)cachedEngagementStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"cachedinteractions.objects"];
}

- (NSArray *)interactionsForCodePoint:(NSString *)codePoint {
	return [codePointInteractions objectForKey:codePoint];
}

- (ATInteraction *)interactionForCodePoint:(NSString *)codePoint {
	NSArray *interactions = [self interactionsForCodePoint:codePoint];
	for (ATInteraction *interaction in interactions) {
		if ([interaction criteriaAreMetForCodePoint:codePoint]) {
			return interaction;
		}
	}
	return nil;
}

- (NSDictionary *)usageDataForInteraction:(ATInteraction *)interation atCodePoint:(NSString *)codePoint {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *installDate = [defaults objectForKey:ATEngagementInstallDateKey];
	NSDate *upgradeDate = [defaults objectForKey:ATEngagementUpgradeDateKey];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];	
	NSUInteger daysSinceInstall = [[calendar components:NSDayCalendarUnit fromDate:installDate toDate:[NSDate date] options:0] day] + 1;
	NSUInteger daysSinceUpgrade = [[calendar components:NSDayCalendarUnit fromDate:upgradeDate toDate:[NSDate date] options:0] day] + 1;
	[calendar release];
	
	NSString *applicationVersion = [defaults objectForKey:ATAppRatingFlowLastUsedVersionKey];
	NSNumber *codepointInvokesTotal = [defaults objectForKey:ATEngagementCodePointsInvokesTotalKey];
	NSNumber *codepointInvokesVersion = [defaults objectForKey:ATEngagementCodePointsInvokesVersionKey];
	NSNumber *interactionInvokesTotal = [defaults objectForKey:ATEngagementInteractionsInvokesTotalKey];
	NSNumber *interactionInvokesVersion = [defaults objectForKey:ATEngagementInteractionsInvokesVersionKey];
	
	NSDictionary *data = @{@"days_since_install": [NSNumber numberWithInt:daysSinceInstall],
						@"days_since_upgrade" : [NSNumber numberWithInt:daysSinceUpgrade],
						@"application_version" : applicationVersion,
						[NSString stringWithFormat:@"code_point_%@_invokes_total", codePoint] : codepointInvokesTotal,
						[NSString stringWithFormat:@"code_point_%@_invokes_version", codePoint] : codepointInvokesVersion,
						[NSString stringWithFormat:@"interactions_%@_invokes_total", interation.identifier] : interactionInvokesTotal,
						[NSString stringWithFormat:@"interactions_%@_invokes_version", interation.identifier] : interactionInvokesVersion};
	return data;
}

@end
