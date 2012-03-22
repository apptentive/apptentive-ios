//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATAppRatingFlow_Private.h"
#import "ATContactStorage.h"
#import "ATWebClient.h"
#import "JSONKit.h"

NSString *const ATAppConfigurationUpdaterFinished = @"ATAppConfigurationUpdaterFinished";
NSString *const ATAppConfigurationLastUpdatePreferenceKey = @"ATAppConfigurationLastUpdatePreferenceKey";

// Interval, in seconds, after which we'll update the configuration.
#define kATAppConfigurationUpdateInterval (60*60*24)

@interface ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration;
@end

@implementation ATAppConfigurationUpdater
+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences = 
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATAppConfigurationLastUpdatePreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldCheckForUpdate {
	[ATAppConfigurationUpdater registerDefaults];	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastCheck = [defaults objectForKey:ATAppConfigurationLastUpdatePreferenceKey];
	
	NSTimeInterval interval = [lastCheck timeIntervalSinceNow];
	
	if (interval <= -kATAppConfigurationUpdateInterval) {
		return YES;
	} else {
		return NO;
	}
	
}
- (void)dealloc {
	[self cancel];
	[super dealloc];
}

- (void)update {
	[self cancel];
	request = [[[ATWebClient sharedClient] requestForGettingAppConfiguration] retain];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			NSLog(@"App configuration result is not NSDictionary!");
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
	}
}
@end

@implementation ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration {
	BOOL hasRatingsChanges = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[ATAppConfigurationUpdater registerDefaults];
	[ATAppRatingFlow_Private registerDefaults];
	[defaults setObject:[NSDate date] forKey:ATAppConfigurationLastUpdatePreferenceKey];
	[defaults synchronize];
	
	NSDictionary *numberObjects = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 @"ratings_clear_on_upgrade", ATAppRatingClearCountsOnUpgradePreferenceKey, 
		 @"ratings_enabled", ATAppRatingEnabledPreferenceKey,
		 @"ratings_days_before_prompt", ATAppRatingDaysBeforePromptPreferenceKey, 
		 @"ratings_days_between_prompts", ATAppRatingDaysBetweenPromptsPreferenceKey, 
		 @"ratings_events_before_prompt", ATAppRatingSignificantEventsBeforePromptPreferenceKey, 
		 @"ratings_uses_before_prompt", ATAppRatingUsesBeforePromptPreferenceKey, nil];
	
	NSArray *boolPreferences = [NSArray arrayWithObjects:@"ratings_clear_on_upgrade", @"ratings_enabled", nil];
	NSObject *ratingsPromptLogic = [jsonRatingConfiguration objectForKey:@"ratings_prompt_logic"];
	
	for (NSString *key in numberObjects) {
		NSObject *value = [jsonRatingConfiguration objectForKey:[numberObjects objectForKey:key]];
		if (!value || ![value isKindOfClass:[NSNumber class]]) {
			continue;
		}
		
		NSNumber *numberValue = (NSNumber *)value;
		
		NSNumber *existingNumber = [defaults objectForKey:key];
		if ([existingNumber isEqualToNumber:numberValue]) {
			continue;
		}
		
		if ([boolPreferences containsObject:[numberObjects objectForKey:key]]) {
			[defaults setObject:numberValue forKey:key];
		} else {
			NSUInteger unsignedIntegerValue = [numberValue unsignedIntegerValue];
			NSNumber *replacementValue = [NSNumber numberWithUnsignedInteger:unsignedIntegerValue];
			
			[defaults setObject:replacementValue forKey:key];
		}
		hasRatingsChanges = YES;
	}
	
	if (ratingsPromptLogic) {
		NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:ratingsPromptLogic];
		if (predicate) {
			[defaults setObject:ratingsPromptLogic forKey:ATAppRatingPromptLogicPreferenceKey];
			hasRatingsChanges = YES;
		}
	}
	
	if (hasRatingsChanges) {
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingSettingsAreFromServerPreferenceKey];
		[defaults synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingPreferencesChangedNotification object:nil];
	}
}
@end

