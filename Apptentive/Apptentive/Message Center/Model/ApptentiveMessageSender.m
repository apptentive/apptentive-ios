//
//  ApptentiveMessageSender.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageSender.h"

@implementation ApptentiveMessageSender

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			return nil;
		}

		_name = JSON[@"name"];
		_identifier = JSON[@"id"];

		NSString *profilePhotoURLString = JSON[@"profile_photo"];
		if ([profilePhotoURLString isKindOfClass:[NSString class]]) {
			_profilePhotoURL = [NSURL URLWithString:profilePhotoURLString];
		}
	}

	return self;
}

- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier profilePhotoURL:(NSURL *)profilePhotoURL {
	self = [super init];

	if (self) {
		_name = name;
		_identifier = identifier;
		_profilePhotoURL = profilePhotoURL;
	}

	return self;
}

@end
