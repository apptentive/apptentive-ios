//
//  Apptentive+Debugging.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive+Debugging.h"
#import "ApptentiveBackend.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"
#import "ApptentiveEngagementManifest.h"

#import "ApptentiveConversation.h"
#import "ApptentiveConversationMetadata.h"
#import "ApptentiveConversationMetadataItem.h"


@implementation Apptentive (Debugging)

- (ApptentiveDebuggingOptions)debuggingOptions {
	return 0;
}

- (NSString *)SDKVersion {
	return kApptentiveVersionString;
}

- (void)setLocalInteractionsURL:(NSURL *)localInteractionsURL {
	self.backend.conversationManager.localEngagementManifestURL = localInteractionsURL;
}

- (NSURL *)localInteractionsURL {
	return self.backend.conversationManager.localEngagementManifestURL;
}

- (NSString *)storagePath {
	return self.backend.supportDirectoryPath;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSDictionary *JSONDictionary = self.backend.conversationManager.manifest.JSONDictionary;

	if (JSONDictionary != nil) {
		NSData *outputJSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:NSJSONWritingPrettyPrinted error:NULL];

		return [[NSString alloc] initWithData:outputJSONData encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

- (NSDictionary *)deviceInfo {
	return Apptentive.shared.backend.conversationManager.activeConversation.device.JSONDictionary;
}

- (NSArray *)engagementEvents {
	NSDictionary *targets = Apptentive.shared.backend.conversationManager.manifest.targets;
	NSArray *localCodePoints = [targets.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", @"local#app#"]];
	NSMutableArray *eventNames = [NSMutableArray array];
	for (NSString *codePoint in localCodePoints) {
		[eventNames addObject:[codePoint substringFromIndex:10]];
	}

	return eventNames;
}

- (NSArray *)engagementInteractions {
	return self.backend.conversationManager.manifest.interactions.allValues;
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
	[self.backend presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

- (void)presentInteractionWithJSON:(NSDictionary *)JSON fromViewController:(UIViewController *)viewController {
	[self.backend presentInteraction:[ApptentiveInteraction interactionWithJSONDictionary:JSON] fromViewController:viewController];
}

- (NSString *)conversationToken {
	return Apptentive.shared.backend.conversationManager.activeConversation.token;
}

- (void)resetSDK {
	[self.backend resetBackend];

	[self setValue:nil forKey:@"backend"];
}

- (NSDictionary *)customPersonData {
	return self.backend.conversationManager.activeConversation.person.customData ?: @{};
}

- (NSDictionary *)customDeviceData {
	return self.backend.conversationManager.activeConversation.device.customData ?: @{};
}

#pragma mark - Conversation metadata

- (NSInteger)numberOfConversations {
	return self.backend.conversationManager.conversationMetadata.items.count;
}

- (NSString *)conversationStateAtIndex:(NSInteger)index {
	ApptentiveConversationState state = ((ApptentiveConversationMetadataItem *)self.backend.conversationManager.conversationMetadata.items[index]).state;
	return NSStringFromApptentiveConversationState(state);
}

- (NSString *)conversationDescriptionAtIndex:(NSInteger)index {
	ApptentiveConversationMetadataItem *item = self.backend.conversationManager.conversationMetadata.items[index];

	NSString *result = [NSString stringWithFormat:@"ID: %@", item.conversationIdentifier];

	if (item.encryptionKey != nil) {
		result = [result stringByAppendingFormat:@" Key: %@", item.encryptionKey];
	}

	return result;
}

- (BOOL)conversationIsActiveAtIndex:(NSInteger)index {
	NSString *activeConversationIdentifier = self.backend.conversationManager.activeConversation.identifier;
	ApptentiveConversationMetadataItem *item = self.backend.conversationManager.conversationMetadata.items[index];

	return [activeConversationIdentifier isEqualToString:item.conversationIdentifier];
}

- (void)deleteConversationAtIndex:(NSInteger)index {
	ApptentiveConversationMetadataItem *item = self.backend.conversationManager.conversationMetadata.items[index];

	[self.backend.conversationManager.conversationMetadata deleteItem:item];
}

@end
