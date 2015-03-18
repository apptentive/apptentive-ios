//
//  ATInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteraction.h"
#import "ATEngagementBackend.h"
#import "ATInteractionUsageData.h"
#import "ATUtilities.h"

@implementation ATInteraction

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.identifier = [jsonDictionary objectForKey:@"id"];
	interaction.priority = [[jsonDictionary objectForKey:@"priority"] integerValue];
	interaction.type = [jsonDictionary objectForKey:@"type"];
	interaction.configuration = [jsonDictionary objectForKey:@"configuration"];
	interaction.version = [jsonDictionary objectForKey:@"version"];
	//NOTE: `vendor` is not currently sent in JSON dictionary.
	
	return [interaction autorelease];
}

+ (ATInteraction *)localAppInteraction {
	ATInteraction *interaction = [[[ATInteraction alloc] init] autorelease];
	interaction.type = ATEngagementCodePointHostAppInteractionKey;
	interaction.vendor = ATEngagementCodePointHostAppVendorKey;
	
	return interaction;
}

+ (ATInteraction *)apptentiveAppInteraction {
	ATInteraction *interaction = [[[ATInteraction alloc] init] autorelease];
	interaction.type = ATEngagementCodePointApptentiveAppInteractionKey;
	interaction.vendor = ATEngagementCodePointApptentiveVendorKey;
	
	return interaction;
}

- (ATInteractionType)interactionType {
	ATInteractionType interactionType;
	if ([self.type isEqualToString:@"UpgradeMessage"]) {
		interactionType = ATInteractionTypeUpgradeMessage;
	} else if ([self.type isEqualToString:@"EnjoymentDialog"]) {
		interactionType = ATInteractionTypeEnjoymentDialog;
	} else if ([self.type isEqualToString:@"RatingDialog"]) {
		interactionType = ATInteractionTypeRatingDialog;
	} else if ([self.type isEqualToString:@"FeedbackDialog"]) {
		interactionType = ATInteractionTypeFeedbackDialog;
	} else if ([self.type isEqualToString:@"MessageCenter"]) {
		interactionType = ATInteractionTypeMessageCenter;
	} else if ([self.type isEqualToString:@"AppStoreRating"]) {
		interactionType = ATInteractionTypeAppStoreRating;
	} else if ([self.type isEqualToString:@"Survey"]) {
		interactionType = ATInteractionTypeSurvey;
	} else if ([self.type isEqualToString:@"TextModal"]) {
		interactionType = ATInteractionTypeTextModal;
	} else if ([self.type isEqualToString:@"NavigateToLink"]) {
		interactionType = ATInteractionTypeNavigateToLink;
	} else {
		interactionType = ATInteractionTypeUnknown;
	}
	
	return interactionType;
}

- (NSString *)description {	
	NSDictionary *description = @{@"identifier" : self.identifier ?: [NSNull null],
								  @"priority" : [NSNumber numberWithInteger:self.priority] ?: [NSNull null],
								  @"type" : self.type ?: [NSNull null],
								  @"configuration" : self.configuration ?: [NSNull null],
								  @"version" : self.version ?: [NSNull null]};
	
	return [description description];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.identifier = [coder decodeObjectForKey:@"identifier"];
		self.priority = [coder decodeIntegerForKey:@"priority"];
		self.type = [coder decodeObjectForKey:@"type"];
		self.configuration = [coder decodeObjectForKey:@"configuration"];
		self.version = [coder decodeObjectForKey:@"version"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeInteger:self.priority forKey:@"priority"];
	[coder encodeObject:self.type forKey:@"type"];
	[coder encodeObject:self.configuration forKey:@"configuration"];
	[coder encodeObject:self.version forKey:@"version"];
}

- (id)copyWithZone:(NSZone *)zone {
    ATInteraction *copy = [[ATInteraction alloc] init];
	
    if (copy) {
		copy.identifier = self.identifier;
		copy.priority = self.priority;
		copy.type = self.type;
		copy.configuration = self.configuration;
		copy.version = self.version;
    }
	
    return copy;
}

- (NSString *)vendor {
	// Currently, all interactions except local app events use `ATEngagementCodePointApptentiveVendorKey`.
	return _vendor ?: ATEngagementCodePointApptentiveVendorKey;
}

- (NSString *)codePointForEvent:(NSString *)event {
	return [ATEngagementBackend codePointForVendor:self.vendor interactionType:self.type event:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController {
	return [self engage:event fromViewController:viewController userInfo:nil];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo {
	return [self engage:event fromViewController:viewController userInfo:userInfo customData:nil extendedData:nil];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	NSString *codePoint = [self codePointForEvent:event];
	
	return [[ATEngagementBackend sharedBackend] engageCodePoint:codePoint fromInteraction:self userInfo:userInfo customData:customData extendedData:extendedData fromViewController:viewController];
}

- (void)dealloc {
	[_identifier release], _identifier = nil;
	[_type release], _type = nil;
	[_configuration release], _configuration = nil;
	[_version release], _version = nil;
	[_vendor release], _vendor = nil;
	
	[super dealloc];
}

@end
