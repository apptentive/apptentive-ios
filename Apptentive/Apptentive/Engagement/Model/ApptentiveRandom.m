//
//  ApptentiveRandom.m
//  Apptentive
//
//  Created by Frank Schmitt on 6/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRandom.h"

static NSString *const RandomValuesKey = @"random_values";

@interface ApptentiveRandom ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSNumber *> *randomValues;

@end

@implementation ApptentiveRandom

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_randomValues = [NSMutableDictionary dictionary];
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		_randomValues = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:RandomValuesKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.randomValues forKey:RandomValuesKey];
}

#pragma mark - Targeting State

- (NSObject *)valueForFieldWithPath:(NSString *)path {
	NSArray *parts = [path componentsSeparatedByString:@"/"];

	if (parts.count > 0 && parts.count <= 2 && [parts.lastObject isEqualToString:@"percent"]) {
		NSString *key = parts.count == 2 ? parts[0] : nil;

		return @([self randomPercentForKey:key]);
	} else {
		ApptentiveLogError(@"Unrecognized field name “%@”", path);
		return nil;
	}
}

- (NSString *)descriptionForFieldWithPath:(NSString *)path {
	NSArray *parts = [path componentsSeparatedByString:@"/"];

	if (parts.count > 0 && parts.count <= 2 && [parts.lastObject isEqualToString:@"percent"]) {
		NSString *key = parts.count == 2 ? parts[0] : nil;

		return [self descriptionOfPercentForKey:key];
	} else {
		return [NSString stringWithFormat:@"Unrecognized engagement field %@", path];
	}
}

#pragma mark - Private

- (NSString *)descriptionOfPercentForKey:(nullable NSString *)key {
	if (key == nil) {
		return @"Random percentage";
	} else if (self.randomValues[key] == nil) {
		return [NSString stringWithFormat:@"Random percentage that will be saved for key “%@”", key];
	} else {
		return [NSString stringWithFormat:@"Random percentage that was saved for key “%@”", key];
	}
}

- (double)randomPercentForKey:(nullable NSString *)key {
	return [self randomValueForKey:key] * 100.0;
}

- (double)randomValueForKey:(nullable NSString *)key {
	if (key == nil) {
		return self.newRandomValue;
	} else {
		if (self.randomValues[key] == nil) {
			self.randomValues[key] = @(self.newRandomValue);
		}

		return self.randomValues[key].doubleValue;
	}
}

- (double)newRandomValue {
#if APPTENTIVE_DEBUG
	ApptentiveLogInfo(@"Note: all random sampling percentages will be assigned/saved as 50% when running debug build.");
	return 0.5;
#else
	return (double)arc4random() / UINT32_MAX;
#endif
}

@end
