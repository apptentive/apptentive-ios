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
@end
