//
//  ATMessageCenterInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"
#import "ATPersonInfo.h"
#import "ATMessageCenterViewController.h"

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
	return self.configuration[@"title"];
}

- (NSString *)greetingTitle {
	return self.configuration[@"greeting_title"];
}

- (NSString *)greetingMessage {
	return self.configuration[@"greeting_message"];
}

- (NSURL *)greetingImageURL {
	NSString *URLString = self.configuration[@"greeting_image_url"];
	
	return (URLString.length > 0) ? [NSURL URLWithString:URLString] : nil;
}

- (NSString *)contextMessageBody {
#warning remove
	return @"Please let us know how to make APPNAME better for you!";
	
	return self.configuration[@"context_message_body"];
}

- (NSString *)confirmationText {
	return self.configuration[@"confirmation"];
}

- (NSString *)statusText {
	return self.configuration[@"status"];
}

- (NSString *)HTTPErrorTitle {
	return self.configuration[@"http_error_title"];
}

- (NSString *)HTTPErrorMessage {
	return self.configuration[@"http_error_message"];
}

- (NSString *)networkErrorTitle {
	return self.configuration[@"network_error_title"];
}

- (NSString *)networkErrorMessage {
	return self.configuration[@"network_error_message"];
}

- (NSString *)missingConfigurationMessage {
	return ATLocalizedString(@"We're attempting to connect. Thanks for your patience!", @"Missing Message Center configuration message (not downloaded yet)");
}

- (NSString *)missingConfigurationNetworkErrorMessage {
	return ATLocalizedString(@"Please connect to the internet to send feedback.", @"Missing Message Center configuration message (no internet connection)");
}

- (NSString *)composerPlaceholderText {
	return self.configuration[@"message_hint_text"];
}

- (NSString *)composerTitleText {
	return self.configuration[@"composer_title"];
}

- (NSString *)composerSaveButtonTitle {
#warning Should come from interaction
	if (self.emailRequired && ![[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidPresentWhoCardKey]) {
		return ATLocalizedString(@"Next", @"Message field save button when email required");
	} else {
		return ATLocalizedString(@"Send", @"Send button title");
	}
}

- (NSString *)whoCardTitle {
	return self.configuration[@"profile_title"];
}

- (NSString *)whoCardSaveButtonTitle {
#warning Should come from interaction
	if (self.emailRequired) {
		return ATLocalizedString(@"Send", @"Send button title");
	} else {
		return self.configuration[@"profile_save_button"];
	}
}

- (BOOL)profileRequested {
#warning remove before flight
	return YES;
	return [self.configuration[@"ask_for_email"] boolValue];
}

- (BOOL)emailRequired {
#warning remove before flight
	return YES;
	return [self.configuration[@"email_required"] boolValue];
}

- (BOOL)brandingEnabled {
	NSNumber *brandingEnabled = self.configuration[@"apptentive_branding_enabled"];
	
	return (brandingEnabled != nil) ? [brandingEnabled boolValue] : YES;
}

@end
