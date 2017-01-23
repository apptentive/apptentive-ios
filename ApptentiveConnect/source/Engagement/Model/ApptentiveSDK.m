//
//  ApptentiveSDK.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"

static NSString *const VersionKey = @"version";
static NSString *const ProgrammingLanguageKey = @"programmingLanguage";
static NSString *const AuthorNameKey = @"authorName";
static NSString *const PlatformKey = @"platform";
static NSString *const DistributionNameKey = @"distributionName";
static NSString *const DistributionVersionKey = @"distributionVersion";

// Legacy keys
static NSString *const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";
static NSString *const ATConversationLastUpdatePreferenceKey = @"ATConversationLastUpdatePreferenceKey";
static NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";

static NSString *_distributionName;
static ApptentiveVersion *_distributionVersion;


@implementation ApptentiveSDK

+ (ApptentiveVersion *)SDKVersion {
	return [[ApptentiveVersion alloc] initWithString:@"3.5.0"];
}

+ (void)setDistributionName:(NSString *)distributionName {
	_distributionName = [distributionName copy];
}

#define DO_EXPAND(VAL) VAL##1
#define EXPAND(VAL) DO_EXPAND(VAL)

+ (NSString *)distributionName {
	if (_distributionName) {
		return _distributionName;
	}

	NSString *result = @"source";

#if APPTENTIVE_FRAMEWORK
	result = @"framework";
#endif

#if APPTENTIVE_BINARY
	result = @"binary";
#endif

#if APPTENTIVE_COCOAPODS
	result = @"CocoaPods-Source";
#endif

#if defined(CARTHAGE) && (EXPAND(CARTHAGE) != 1)
	result = @"Carthage-Source";
#endif

	return result;
}

+ (void)setDistributionVersion:(ApptentiveVersion *)distributionVersion {
	_distributionVersion = distributionVersion;
}

+ (ApptentiveVersion *)distributionVersion {
	if (_distributionVersion) {
		return _distributionVersion;
	} else {
		return [self SDKVersion];
	}
}

- (instancetype)initWithCurrentSDK {
	self = [super init];

	if (self) {
		_version = [[self class] SDKVersion];
		_programmingLanguage = @"Objective-C";
		_authorName = @"Apptentive, Inc.";
		_platform = @"iOS";
		_distributionName = [[self class] distributionName];
		_distributionVersion = [[self class] distributionVersion];
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
		NSDictionary *lastConversationUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:ATConversationLastUpdateValuePreferenceKey];
		NSDictionary *SDK = lastConversationUpdate[@"sdk"];

		_version = [[ApptentiveVersion alloc] initWithString:SDK[@"version"]];
		_programmingLanguage = SDK[@"programming_language"];
		_authorName = SDK[@"author_name"];
		_platform = SDK[@"platform"];
		_distributionName = SDK[@"distribution"];
		_distributionVersion = [[ApptentiveVersion alloc] initWithString:SDK[@"distribution_version"]];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATConversationLastUpdateValuePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATConversationLastUpdatePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATCurrentConversationPreferenceKey];
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
