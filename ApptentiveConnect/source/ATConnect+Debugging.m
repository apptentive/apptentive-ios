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

- (NSString *)SDKVersion {
	return kATConnectVersionString;
}

- (NSString *)APIKey {
	return self.apiKey;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSData *rawJSONData = [ATEngagementBackend sharedBackend].engagementManifestJSON;

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
	return [[[[ATDeviceInfo alloc] init] apiJSON] objectForKey:@"device"];
}

- (NSString *)personName {
	return [ATPersonInfo currentPerson].name;
}

- (NSString *)personEmailAddress {
	return [ATPersonInfo currentPerson].emailAddress;
}

@end
