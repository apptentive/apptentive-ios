//
//  ApptentiveSDK.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"

static NSString * const VersionKey = @"version";
static NSString * const ProgrammingLanguageKey = @"programmingLanguage";
static NSString * const AuthorNameKey = @"authorName";
static NSString * const PlatformKey = @"platform";
static NSString * const DistributionNameKey = @"distributionName";
static NSString * const DistributionVersionKey = @"distributionVersion";

@implementation ApptentiveSDK

- (instancetype)initWithCurrentSDK {
	self = [super init];

	if (self) {
		_version = [[ApptentiveVersion alloc] initWithString:@"3.5.0"];
		_programmingLanguage = @"Objective-C";
		_authorName = @"Apptentive, Inc.";
		_platform = @"iOS";
#warning figure out a way to inject these
		_distributionName = @"source";
		_distributionVersion = [[ApptentiveVersion alloc] initWithString:@"3.5.0"];
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];

	if (self) {
		_version = [coder decodeObjectOfClass:[ApptentiveVersion class] forKey:VersionKey];
		_programmingLanguage = [coder decodeObjectOfClass:[NSString class] forKey:ProgrammingLanguageKey];
		_authorName = [coder decodeObjectOfClass:[NSString class] forKey:AuthorNameKey];
		_platform = [coder decodeObjectOfClass:[NSString class] forKey:PlatformKey];
		_distributionName = [coder decodeObjectOfClass:[NSString class] forKey:DistributionNameKey];
		_distributionVersion = [coder decodeObjectOfClass:[ApptentiveVersion class] forKey:DistributionVersionKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];

	[coder encodeObject:self.version forKey:VersionKey];
	[coder encodeObject:self.programmingLanguage forKey:ProgrammingLanguageKey];
	[coder encodeObject:self.authorName forKey:AuthorNameKey];
	[coder encodeObject:self.platform forKey:PlatformKey];
	[coder encodeObject:self.distributionName forKey:DistributionNameKey];
	[coder encodeObject:self.distributionVersion forKey:DistributionVersionKey];
}

- (instancetype)initAndMigrate {
	self = [super init];

	if (self) {
		NSString * const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";

		NSDictionary *lastConversationUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:ATConversationLastUpdateValuePreferenceKey];
		NSDictionary *SDK = lastConversationUpdate[@"sdk"];

		_version = [[ApptentiveVersion alloc] initWithString:SDK[@"version"]];
		_programmingLanguage = SDK[@"programming_language"];
		_authorName = SDK[@"author_name"];
		_platform = SDK[@"platform"];
		_distributionName = SDK[@"distribution"];
		_distributionVersion =  [[ApptentiveVersion alloc] initWithString:SDK[@"distribution_version"]];
	}

	return self;
}

@end

@implementation ApptentiveSDK (JSON)

- (NSString *)versionString {
	return self.version.versionString;
}

- (NSString *)distributionVersionString {
	return self.distributionVersion.versionString;
}

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
			 @"version": NSStringFromSelector(@selector(versionString)),
			 @"programming_language": NSStringFromSelector(@selector(programmingLanguage)),
			 @"author_name": NSStringFromSelector(@selector(authorName)),
			 @"platform": NSStringFromSelector(@selector(platform)),
			 @"distribution": NSStringFromSelector(@selector(distributionName)),
			 @"distribution_version": NSStringFromSelector(@selector(distributionVersionString))
			 };
}

@end
