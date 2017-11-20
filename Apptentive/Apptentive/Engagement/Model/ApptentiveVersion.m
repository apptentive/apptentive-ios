//
//  ApptentiveVersion.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/17/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveVersion.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const VersionStringKey = @"versionString";
static NSString *const MajorKey = @"major";
static NSString *const MinorKey = @"minor";
static NSString *const PatchKey = @"patch";


@implementation ApptentiveVersion

- (instancetype)initWithString:(NSString *)versionString {
	self = [super init];

	if (self) {
		if (versionString.length == 0) {
			versionString = @"0.0.0";
		}

		_versionString = versionString;

		NSInteger major = 0, minor = 0, patch = 0;

		NSScanner *scanner = [NSScanner scannerWithString:versionString];
		[scanner scanInteger:&major];
		[scanner scanString:@"." intoString:NULL];
		[scanner scanInteger:&minor];
		[scanner scanString:@"." intoString:NULL];
		[scanner scanInteger:&patch];

		if (scanner.scanLocation == versionString.length && major >= 0 && minor >= 0 && patch >= 0) {
			_major = major;
			_minor = minor;
			_patch = patch;
		} else {
			_major = -1;
			_minor = -1;
			_patch = -1;
		}
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_versionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:VersionStringKey];
		_major = [aDecoder decodeIntegerForKey:MajorKey];
		_minor = [aDecoder decodeIntegerForKey:MinorKey];
		_patch = [aDecoder decodeIntegerForKey:PatchKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:self.versionString forKey:VersionStringKey];
	[aCoder encodeInteger:self.major forKey:MajorKey];
	[aCoder encodeInteger:self.minor forKey:MinorKey];
	[aCoder encodeInteger:self.patch forKey:PatchKey];
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[ApptentiveVersion class]]) {
		return [self isEqualToVersion:(ApptentiveVersion *)object];
	} else {
		return NO;
	}
}

- (BOOL)isEqualToVersion:(ApptentiveVersion *)version {
	if (self.major == -1) {
		return [self.versionString isEqualToString:version.versionString];
	} else if (self.major == version.major && self.minor == version.minor && self.patch == version.patch) {
		return YES;
	} else {
		return NO;
	}
}

@end


@implementation ApptentiveVersion (JSON)

- (NSDictionary *)JSONDictionary {
	return @{ @"_type": @"version",
		@"version": self.versionString };
}

@end

NS_ASSUME_NONNULL_END
