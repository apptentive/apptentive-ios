//
//  ATConnect+Debugging.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATConnect+Debugging.h"
#import "ATWebClient.h"
#import "ATBackend.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"
#import "ATDeviceInfo.h"

@implementation ATConnect (Debugging)

+ (NSString *)supportDirectoryPath {
	static NSString *_supportDirectoryPath;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
		NSString *apptentiveDirectoryPath = [appSupportDirectoryPath stringByAppendingPathComponent:@"com.apptentive.feedback"];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *error = nil;

		if (![fm createDirectoryAtPath:apptentiveDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ATLogError(@"Failed to create support directory: %@", apptentiveDirectoryPath);
			ATLogError(@"Error was: %@", error);
			return;
		}

		if (![fm setAttributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication } ofItemAtPath:apptentiveDirectoryPath error:&error]) {
			ATLogError(@"Failed to set file protection level: %@", apptentiveDirectoryPath);
			ATLogError(@"Error was: %@", error);
		}

		_supportDirectoryPath = apptentiveDirectoryPath;
	});

	return _supportDirectoryPath;
}

- (NSString *)SDKVersion {
	return kATConnectVersionString;
}

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL storagePath:(nonnull NSString *)storagePath {
	if (![baseURL isEqual:self.baseURL]) {
		ATLogInfo(@"Base URL of %@ will not be used due to SDK version. Using %@ instead.", baseURL, self.baseURL);
	}

	if (![storagePath isEqualToString:self.storagePath]) {
		ATLogInfo(@"Storage path of %@ will not be used due to SDK version. Using %@ instead.", storagePath, self.storagePath);
	}

	self.apiKey = APIKey;
}

- (NSString *)storagePath {
	return [self class].supportDirectoryPath;
}

- (NSURL *)baseURL {
	return self.webClient.baseURL;
}

- (NSString *)APIKey {
	return self.apiKey;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSData *rawJSONData = self.engagementBackend.engagementManifestJSON;

	if (rawJSONData != nil) {
		NSData *outputJSONData = nil;

		// try to pretty-print by round-tripping through NSJSONSerialization
		id JSONObject = [NSJSONSerialization	 JSONObjectWithData:rawJSONData options:0 error:NULL];
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
	return [[[[ATDeviceInfo alloc] init] dictionaryRepresentation] objectForKey:@"device"];
}

- (NSArray *)engagementInteractions {
	return [self.engagementBackend allEngagementInteractions];
}

- (NSInteger)numberOfEngagementInteractions {
	return [[self engagementInteractions] count];
}

- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return [interaction.configuration objectForKey:@"name"] ?: [interaction.configuration objectForKey:@"title"] ?: @"Untitled Interaction";
}

- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index {
	ATInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return interaction.type;
}

- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController {
	[self.engagementBackend presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

@end
