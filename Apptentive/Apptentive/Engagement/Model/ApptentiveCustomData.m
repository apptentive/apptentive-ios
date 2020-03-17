//
//  ApptentiveCustomData.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const CustomDataKey = @"customData";
static NSString *const IdentifierKey = @"identifier";


@interface ApptentiveCustomData ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSObject<NSCoding> *> *mutableCustomData;

@end


@implementation ApptentiveCustomData

- (instancetype)init {
	self = [super init];

	if (self) {
		_mutableCustomData = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (instancetype)initWithCustomData:(NSDictionary *)customData {
	self = [super init];

	if (self) {
		_mutableCustomData = [customData mutableCopy] ?: [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		NSSet *allowedClasses = [NSSet setWithArray:@[[NSDictionary class], [NSString class]]];
		_mutableCustomData = [aDecoder decodeObjectOfClasses:allowedClasses forKey:CustomDataKey];
		_identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.mutableCustomData forKey:CustomDataKey];
	[aCoder encodeObject:self.identifier forKey:IdentifierKey];
}

- (NSDictionary<NSString *, NSObject<NSCoding> *> *)customData {
	return [self.mutableCustomData copy];
}

- (void)addCustomString:(NSString *)string withKey:(NSString *)key {
	if (string != nil && key != nil) {
		[self.mutableCustomData setObject:string forKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to add custom data string with nil key and/or value.");
	}
}

- (void)addCustomNumber:(NSNumber *)number withKey:(NSString *)key {
	if (number != nil && key != nil) {
		[self.mutableCustomData setObject:number forKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to add custom data number with nil key and/or value.");
	}
}

- (void)addCustomBool:(BOOL)boolValue withKey:(NSString *)key {
	if (key != nil) {
		[self.mutableCustomData setObject:@(boolValue) forKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to add custom data boolean with nil key.");
	}
}

- (void)removeCustomValueWithKey:(NSString *)key {
	if (key != nil) {
		[self.mutableCustomData removeObjectForKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to remove custom data with nil key.");
	}
}

+ (NSArray *)sensitiveKeys {
	return @[@"custom_data"];
}

@end


@implementation ApptentiveCustomData (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{ @"custom_data": NSStringFromSelector(@selector(customData)) };
}

@end

@implementation ApptentiveCustomData (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	if ([path hasPrefix:@"custom_data/"]) {
		NSString *customDataKey = [path substringFromIndex:@"custom_data/".length];
		return self.customData[customDataKey];
	}

	ApptentiveLogError(@"Unrecognized field name “%@”", path);
	return nil;
}

@end

NS_ASSUME_NONNULL_END
