//
//  ApptentiveMessagePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessagePayload.h"
#import "ApptentiveMessage.h"

@interface ApptentiveMessagePayload ()

@property (strong, nonatomic) NSDictionary *superContents;

@end

@implementation ApptentiveMessagePayload

- (instancetype)initWithMessage:(ApptentiveMessage *)message {
	self = [super init];

	if (self) {
		_message = message;
		_superContents = super.contents;

		[message updateWithLocalIdentifier:_superContents[@"nonce"]];
	}

	return self;
}

- (NSString *)path {
	return @"messages";
}

- (NSDictionary *)JSONDictionary {
	NSMutableDictionary *JSON = [self.superContents mutableCopy];

	if (self.message.body) {
		JSON[@"body"] = self.message.body;
	}

	JSON[@"automated"] = @(self.message.automated);
	JSON[@"hidden"] = @(self.message.state == ApptentiveMessageStateHidden);

	if (self.message.customData) {
		NSDictionary *customDataDictionary = self.message.customData;
		if (customDataDictionary && customDataDictionary.count) {
			JSON[@"custom_data"] = customDataDictionary;
		}
	}

	return JSON;
}

- (NSArray *)attachments {
	return self.message.attachments ?: @[];
}

- (NSString *)localIdentifier {
	return self.message.localIdentifier;
}

@end
