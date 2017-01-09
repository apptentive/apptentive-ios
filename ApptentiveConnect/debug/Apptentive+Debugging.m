//
//  Apptentive+Debugging.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive+Debugging.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"

@implementation Apptentive (Debugging)

- (ApptentiveDebuggingOptions)debuggingOptions {
	return 0;
}

- (NSString *)SDKVersion {
	return self.backend.session.SDK.version.versionString;
}

- (void)setLocalInteractionsURL:(NSURL *)localInteractionsURL {
	self.engagementBackend.localEngagementManifestURL = localInteractionsURL;
}

- (NSURL *)localInteractionsURL {
	return self.engagementBackend.localEngagementManifestURL;
}

- (NSString *)storagePath {
	return self.backend.supportDirectoryPath;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSData *rawJSONData = self.engagementBackend.engagementManifestJSON;

	if (rawJSONData != nil) {
		NSData *outputJSONData = nil;

		// try to pretty-print by round-tripping through NSJSONSerialization
		id JSONObject = [NSJSONSerialization JSONObjectWithData:rawJSONData options:0 error:NULL];
		if (JSONObject) {
			outputJSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:NULL];
		}

		// fall back to ugly JSON
		if (!outputJSONData) {
			outputJSONData = rawJSONData;
		}

		return [[NSString alloc] initWithData:outputJSONData encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

- (NSDictionary *)deviceInfo {
	return Apptentive.shared.backend.session.device.JSONDictionary;
}

- (NSArray *)engagementEvents {
	return [self.engagementBackend targetedLocalEvents];
}

- (NSArray *)engagementInteractions {
	return [self.engagementBackend allEngagementInteractions];
}

- (NSInteger)numberOfEngagementInteractions {
	return [[self engagementInteractions] count];
}

- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index {
	ApptentiveInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return [interaction.configuration objectForKey:@"name"] ?: [interaction.configuration objectForKey:@"title"] ?: @"Untitled Interaction";
}

- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index {
	ApptentiveInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return interaction.type;
}

- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController {
	[self.engagementBackend presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

- (void)presentInteractionWithJSON:(NSDictionary *)JSON fromViewController:(UIViewController *)viewController {
	[self.engagementBackend presentInteraction:[ApptentiveInteraction interactionWithJSONDictionary:JSON] fromViewController:viewController];
}

- (NSString *)conversationToken {
	return Apptentive.shared.backend.session.token;
}

- (void)resetSDK {
	// TODO: use forthcoming session-clearing system
	NSAssert(NO, @"This isn't implemented yet");
}

- (NSDictionary *)customPersonData {
	return self.backend.session.person.customData;
}

- (NSDictionary *)customDeviceData {
	return self.backend.session.device.customData;
}

@end
