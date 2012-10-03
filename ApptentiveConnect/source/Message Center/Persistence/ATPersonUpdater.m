//
//  ATPersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonUpdater.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";


@interface ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson;
@end

@implementation ATPersonUpdater
@synthesize delegate;

+ (BOOL)personExists {
	ATPerson *currentPerson = [ATPersonUpdater currentPerson];
	if (currentPerson == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATPerson *)currentPerson {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	ATPerson *person = (ATPerson *)[defaults objectForKey:ATCurrentPersonPreferenceKey];
	return person;
}

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)update {
	[self cancel];
	request = [[[ATWebClient sharedClient] requestForPostingPerson] retain];
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

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
			[delegate configurationUpdaterDidFinish:YES];
		} else {
			NSLog(@"App configuration result is not NSDictionary!");
			[delegate configurationUpdaterDidFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate configurationUpdaterDidFinish:NO];
	}
}
@end

@implementation ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonConfiguration {
	BOOL hasConfigurationChanges = NO;
	
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
	 @"ratings_uses_before_prompt", ATAppRatingUsesBeforePromptPreferenceKey,
	 @"metrics_enabled", ATAppConfigurationMetricsEnabledPreferenceKey,
	 nil];
	
	NSArray *boolPreferences = [NSArray arrayWithObjects:@"ratings_clear_on_upgrade", @"ratings_enabled", @"metrics_enabled", nil];
	NSObject *ratingsPromptLogic = [jsonConfiguration objectForKey:@"ratings_prompt_logic"];
	
	for (NSString *key in numberObjects) {
		NSObject *value = [jsonConfiguration objectForKey:[numberObjects objectForKey:key]];
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
		hasConfigurationChanges = YES;
	}
	
	if (ratingsPromptLogic) {
		NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:ratingsPromptLogic withPredicateInfo:nil];
		if (predicate) {
			[defaults setObject:ratingsPromptLogic forKey:ATAppRatingPromptLogicPreferenceKey];
			hasConfigurationChanges = YES;
		}
	}
	
	if ([jsonConfiguration objectForKey:@"review_url"]) {
		NSString *reviewURLString = [jsonConfiguration objectForKey:@"review_url"];
		[defaults setObject:reviewURLString forKey:ATAppRatingReviewURLPreferenceKey];
	}
	
	if ([jsonConfiguration objectForKey:@"cache-expiration"]) {
		NSString *expirationDateString = [jsonConfiguration objectForKey:@"cache-expiration"];
		NSDate *expirationDate = [ATUtilities dateFromISO8601String:expirationDateString];
		if (expirationDate) {
			[defaults setObject:expirationDate forKey:ATAppConfigurationExpirationPreferenceKey];
		}
	}
	
	if (hasConfigurationChanges) {
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingSettingsAreFromServerPreferenceKey];
		[defaults synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:nil];
	}
}
@end

