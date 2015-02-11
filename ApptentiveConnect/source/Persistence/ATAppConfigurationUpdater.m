//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATContactStorage.h"
#import "ATUtilities.h"
#import "ATWebClient.h"

NSString *const ATConfigurationPreferencesChangedNotification = @"ATConfigurationPreferencesChangedNotification";
NSString *const ATAppConfigurationLastUpdatePreferenceKey = @"ATAppConfigurationLastUpdatePreferenceKey";
NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
NSString *const ATAppConfigurationMetricsEnabledPreferenceKey = @"ATAppConfigurationMetricsEnabledPreferenceKey";
NSString *const ATAppConfigurationMessageCenterEnabledKey = @"ATAppConfigurationMessageCenterEnabledKey";
NSString *const ATAppConfigurationHideBrandingKey = @"ATAppConfigurationHideBrandingKey";

NSString *const ATAppConfigurationMessageCenterTitleKey = @"ATAppConfigurationMessageCenterTitleKey";
NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterForegroundRefreshIntervalKey";
NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey";
NSString *const ATAppConfigurationMessageCenterEmailRequiredKey = @"ATAppConfigurationMessageCenterEmailRequiredKey";

NSString *const ATAppConfigurationAppDisplayNameKey = @"ATAppConfigurationAppDisplayNameKey";

// Interval, in seconds, after which we'll update the configuration.
#if APPTENTIVE_DEBUG
#define kATAppConfigurationUpdateInterval (3)
#else
#define kATAppConfigurationUpdateInterval (60*60*24)
#endif


@interface ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration maxAge:(NSTimeInterval)expiresMaxAge;
@end

@implementation ATAppConfigurationUpdater
+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences = 
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATAppConfigurationLastUpdatePreferenceKey,
	 [NSNumber numberWithBool:YES], ATAppConfigurationMetricsEnabledPreferenceKey,
	 [NSNumber numberWithInt:20], ATAppConfigurationMessageCenterForegroundRefreshIntervalKey,
	 [NSNumber numberWithInt:60], ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey,
	 [NSNumber numberWithBool:NO], ATAppConfigurationMessageCenterEmailRequiredKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldCheckForUpdate {
	[ATAppConfigurationUpdater registerDefaults];	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastCheck = [defaults objectForKey:ATAppConfigurationLastUpdatePreferenceKey];
	
#ifndef APPTENTIVE_DEBUG
	NSDate *expiration = [defaults objectForKey:ATAppConfigurationExpirationPreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			return NO;
		}
	}
#endif
	
	// Fall back to the defaults.
	NSTimeInterval interval = [lastCheck timeIntervalSinceNow];
	
	if (interval <= -kATAppConfigurationUpdateInterval) {
		return YES;
	} else {
		return NO;
	}
}


- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)aDelegate {
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
			[self processResult:(NSDictionary *)result maxAge:[sender expiresMaxAge]];
			[delegate configurationUpdaterDidFinish:YES];
		} else {
			ATLogError(@"App configuration result is not NSDictionary!");
			[delegate configurationUpdaterDidFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate configurationUpdaterDidFinish:NO];
	}
}
@end

@implementation ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonConfiguration maxAge:(NSTimeInterval)expiresMaxAge {
	BOOL hasConfigurationChanges = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[ATAppConfigurationUpdater registerDefaults];
	[defaults setObject:[NSDate date] forKey:ATAppConfigurationLastUpdatePreferenceKey];
	
	NSDictionary *numberObjects = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 @"metrics_enabled", ATAppConfigurationMetricsEnabledPreferenceKey,
		 @"message_center_enabled", ATAppConfigurationMessageCenterEnabledKey,
		 @"hide_branding", ATAppConfigurationHideBrandingKey,
		 nil];
	
	NSArray *boolPreferences = [NSArray arrayWithObjects:@"ratings_clear_on_upgrade", @"ratings_enabled", @"metrics_enabled", @"message_center_enabled", @"hide_branding", nil];
	
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
	
	// Store expiration.
	if (expiresMaxAge > 0) {
		NSDate *date = [NSDate dateWithTimeInterval:expiresMaxAge sinceDate:[NSDate date]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:date forKey:ATAppConfigurationExpirationPreferenceKey];
		[defaults synchronize];
	}
	
	if ([jsonConfiguration objectForKey:@"message_center"]) {
		NSObject *messageCenterConfiguration = [jsonConfiguration objectForKey:@"message_center"];
		if ([messageCenterConfiguration isKindOfClass:[NSDictionary class]]) {
			NSDictionary *mc = (NSDictionary *)messageCenterConfiguration;
			NSString *title = [mc objectForKey:@"title"];
			NSString *oldTitle = [defaults objectForKey:ATAppConfigurationMessageCenterTitleKey];
			if (!oldTitle || ![oldTitle isEqualToString:title]) {
				[defaults setObject:title forKey:ATAppConfigurationMessageCenterTitleKey];
				hasConfigurationChanges = YES;
			}
			
			NSNumber *fgRefresh = [mc objectForKey:@"fg_poll"];
			NSNumber *oldFGRefresh = [defaults objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
			if (!oldFGRefresh || [oldFGRefresh intValue] != [fgRefresh intValue]) {
				[defaults setObject:fgRefresh forKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
				hasConfigurationChanges = YES;
			}
			
			NSNumber *bgRefresh = [mc objectForKey:@"bg_poll"];
			NSNumber *oldBGRefresh = [defaults objectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
			if (!oldBGRefresh || [oldBGRefresh intValue] != [bgRefresh intValue]) {
				[defaults setObject:bgRefresh forKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
				hasConfigurationChanges = YES;
			}
			
			NSNumber *emailRequired = [mc objectForKey:@"email_required"];
			if (emailRequired) {
				NSNumber *oldEmailRequired = [defaults objectForKey:ATAppConfigurationMessageCenterEmailRequiredKey];
				if (!oldEmailRequired || [emailRequired boolValue] != [oldEmailRequired boolValue]) {
					[defaults setObject:emailRequired forKey:ATAppConfigurationMessageCenterEmailRequiredKey];
					hasConfigurationChanges = YES;
				}
			}
		}
	}
	
	BOOL setAppName = NO;
	if ([jsonConfiguration objectForKey:@"app_display_name"]) {
		NSObject *appNameObject = [jsonConfiguration objectForKey:@"app_display_name"];
		if ([appNameObject isKindOfClass:[NSString class]]) {
			[defaults setObject:appNameObject forKey:ATAppConfigurationAppDisplayNameKey];
			setAppName = YES;
		}
	}
	if (!setAppName) {
		[defaults removeObjectForKey:ATAppConfigurationAppDisplayNameKey];
	}
	
	if (hasConfigurationChanges) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:nil];
	}
}
@end

