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
	return [self stringForKey:@"greeting_title" fallback:ATLocalizedString(@"Hello!", @"Default Message Center Greeting Title Text")];
}

- (NSString *)greetingMessage {
	return [self stringForKey:@"greeting_message" fallback:ATLocalizedString(@"We’d love to get feedback from you on our app. The more details you can provide, the better.", @"Default Message Center Greeting Message Text")];
}

- (NSURL *)greetingImageURL {
	NSString *URLString = [self stringForKey:@"greeting_image_url" fallback:nil];
	
	return (URLString.length > 0) ? [NSURL URLWithString:URLString] : nil;
}

- (NSString *)contextMessageTitle {
#warning remove
	return @"Context_Message_Title!";
	
	return [self stringForKey:@"context_message_title" fallback:nil];
}

- (NSString *)contextMessageBody {
#warning remove
	return @"Please let us know how to make APPNAME better for you!";
	
	return [self stringForKey:@"context_message_body" fallback:nil];
}

- (NSString *)confirmationText {
	return [self stringForKey:@"confirmation" fallback:ATLocalizedString(@"Thank you!", @"Default Message Center Confirmation Text")];
}

- (NSString *)statusText {
	return [self stringForKey:@"status" fallback:nil];
}

- (NSString *)HTTPErrorTitle {
	return [self stringForKey:@"http_error_title" fallback:ATLocalizedString(@"It looks like we're having trouble sending your message.", @"Message Center HTTP error message title")];
}

- (NSString *)HTTPErrorMessage {
	return [self stringForKey:@"http_error_message" fallback:ATLocalizedString(@"We’ve saved it and will try sending it again soon.", @"Message Center HTTP error Message.")];
}

- (NSString *)networkErrorTitle {
	return [self stringForKey:@"network_error_title" fallback:ATLocalizedString(@"It looks like you aren’t connected to the internet right now.", @"Message Center network error message title")];
}

- (NSString *)networkErrorMessage {
	return [self stringForKey:@"network_error_message" fallback:ATLocalizedString(@"We’ve saved your message and will try again when we detect a connection.", @"Message Center network error Message.")];
}

- (NSString *)missingConfigurationMessage {
	return ATLocalizedString(@"We're attempting to connect. Thanks for your patience!", @"Missing Message Center configuration message (not downloaded yet)");
}

- (NSString *)missingConfigurationNetworkErrorMessage {
	return ATLocalizedString(@"Please connect to the internet to send feedback.", @"Missing Message Center configuration message (no internet connection)");
}

- (NSString *)composerPlaceholderText {
	return [self stringForKey:@"message_hint_text" fallback:ATLocalizedString(@"Please leave detailed feedback", @"Message field placeholder text")];
}

- (NSString *)composerTitleText {
	return [self stringForKey:@"composer_title" fallback:ATLocalizedString(@"New Message", @"Title above message field")];
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
