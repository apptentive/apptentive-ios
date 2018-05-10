//
//  ApptentiveCount.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCount.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const TotalCountKey = @"totalCount";
static NSString *const VersionCountKey = @"versionCount";
static NSString *const BuildCountKey = @"buildCount";
static NSString *const LastInvokedKey = @"lastInvoked";


@implementation ApptentiveCount

- (instancetype)init {
	return [self initWithTotalCount:0 versionCount:0 buildCount:0 lastInvoked:nil];
}

- (instancetype)initWithTotalCount:(NSInteger)totalCount versionCount:(NSInteger)versionCount buildCount:(NSInteger)buildCount lastInvoked:(nullable NSDate *)date {
	self = [super init];
	if (self) {
		_totalCount = totalCount;
		_versionCount = versionCount;
		_buildCount = buildCount;
		_lastInvoked = date;
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		_totalCount = [coder decodeIntegerForKey:TotalCountKey];
		_versionCount = [coder decodeIntegerForKey:VersionCountKey];
		_buildCount = [coder decodeIntegerForKey:BuildCountKey];
		_lastInvoked = [coder decodeObjectOfClass:[NSDate class] forKey:LastInvokedKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInteger:self.totalCount forKey:TotalCountKey];
	[coder encodeInteger:self.versionCount forKey:VersionCountKey];
	[coder encodeInteger:self.buildCount forKey:BuildCountKey];
	[coder encodeObject:self.lastInvoked forKey:LastInvokedKey];
}

- (void)resetAll {
	_totalCount = 0;
	_versionCount = 0;
	_buildCount = 0;
	_lastInvoked = nil;
}

- (void)resetVersion {
	_versionCount = 0;
}

- (void)resetBuild {
	_buildCount = 0;
}

- (void)invoke {
	_versionCount++;
	_buildCount++;
	_totalCount++;
	_lastInvoked = [NSDate date]; // TODO: inject as dependency?
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@] totalCount=%ld versionCount=%ld buildCount=%ld lastInvoked=%@", NSStringFromClass([self class]), (unsigned long)_totalCount, (unsigned long)_versionCount, (unsigned long)_buildCount, _lastInvoked];
}

@end


@implementation ApptentiveCount (JSON)

- (NSNumber *)boxedTotalCount {
	return @(self.totalCount);
}

- (NSNumber *)boxedVersionCount {
	return @(self.versionCount);
}

- (NSNumber *)boxedBuildCount {
	return @(self.buildCount);
}

- (NSNumber *)lastInvokedTimestamp {
	return @(self.lastInvoked.timeIntervalSince1970); // TODO: Is this the right format?
}

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"totalCount": NSStringFromSelector(@selector(boxedTotalCount)),
		@"versionCount": NSStringFromSelector(@selector(boxedVersionCount)),
		@"buildCount": NSStringFromSelector(@selector(boxedBuildCount)),
		@"lastInvoked": NSStringFromSelector(@selector(lastInvokedTimestamp))
	};
}

@end

@implementation ApptentiveCount (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	NSArray *parts = [path componentsSeparatedByString:@"/"];
	NSString *invokesOrTime = parts[0];
	NSString *scope = parts[1];

	if ([invokesOrTime isEqualToString:@"invokes"]) {
		if ([scope isEqualToString:@"total"]) {
			return @(self.totalCount);
		} else if ([scope isEqualToString:@"cf_bundle_short_version_string"]) {
			return @(self.versionCount);
		} else if ([scope isEqualToString:@"cf_bundle_version"]) {
			return @(self.buildCount);
		}

		ApptentiveLogError(@"Unrecognized field name “%@”", path);
		return nil;
	} else if ([invokesOrTime isEqualToString:@"last_invoked_at"] && [scope isEqualToString:@"total"]) {
		return self.lastInvoked;
	}

	ApptentiveLogError(@"Unrecognized field name “%@”", path);
	return nil;
}

@end

NS_ASSUME_NONNULL_END
