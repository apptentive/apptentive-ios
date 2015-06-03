//
//  ATMessageCenterInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"

@implementation ATMessageCenterInteraction

+ (ATMessageCenterInteraction *)messageCenterInteraction {
	ATMessageCenterInteraction *messageCenterInteraction = [[ATMessageCenterInteraction alloc] init];
	messageCenterInteraction.type = @"MessageCenter";
	
	return messageCenterInteraction;
}

- (id)copyWithZone:(NSZone *)zone {
	ATMessageCenterInteraction *copy = (ATMessageCenterInteraction *)[super copyWithZone:zone];
	
	return copy;
}

- (NSString *)title {
	return [self stringForKey:@"title" fallback:ATLocalizedString(@"Message Center", @"Default Message Center Title Text")];
}

- (NSString *)greetingTitle {
	return [self stringForKey:@"greeting_title" fallback:ATLocalizedString(@"I’m sorry to hear that!", @"Default Message Center Greeting Title Text")];
}

- (NSString *)greetingMessage {
	return [self stringForKey:@"greeting_message" fallback:ATLocalizedString(@"Please leave us some feedback so we can make the app better for you.", @"Default Message Center Greeting Message Text")];
}

- (NSString *)confirmationText {
	return [self stringForKey:@"confirmation" fallback:ATLocalizedString(@"Thank you!", @"Default Message Center Confirmation Text")];
}

- (NSString *)statusText {
	return [self stringForKey:@"status" fallback:nil];
}

- (NSURL *)greetingImageURL {
	NSString *URLString = [self stringForKey:@"image_url" fallback:nil];
	
	return (URLString.length > 0) ? [NSURL URLWithString:URLString] : nil;
}

- (BOOL)brandingEnabled {
	NSNumber *brandingEnabled = self.configuration[@"apptentive_branding_enabled"];
	
	return (brandingEnabled != nil) ? [brandingEnabled boolValue] : YES;
}

#pragma mark - Private

- (NSString *)stringForKey:(NSString *)key fallback:(NSString *)fallbackString {
	NSString *result =  self.configuration[key];
 
	if (!result) {
		// TODO: get value from global config
	}
	
	if (!result) {
		result = fallbackString ?: @"";
	}
	
	return result;
}

@end
