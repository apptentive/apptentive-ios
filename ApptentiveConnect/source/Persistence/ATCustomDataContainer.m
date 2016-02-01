//
//  ATCustomDataContainer.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/5/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATCustomDataContainer.h"

NSString *const ATCustomDataKey = @"customData";
NSString *const ATDataNeedsSaveNotification = @"ATDataNeedsSaveNotification";

@implementation ATCustomDataContainer

+ (instancetype)newInstanceFromDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithJSONDictionary:dictionary];
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_customData = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		_customData = [[JSON objectForKey:@"custom_data"] mutableCopy] ?: [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_customData = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:ATCustomDataKey] ?: [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.customData forKey:ATCustomDataKey];
}

- (NSDictionary *)dictionaryRepresentation {
	return @{ @"custom_data": self.customData };
}

- (void)saveAndFlagForUpdate {
	[[NSNotificationCenter defaultCenter] postNotificationName:ATDataNeedsSaveNotification object:self];
}

- (void)setCustomDataString:(NSString *)string forKey:(NSString *)key {
	[self setCustomData:string forKey:key];
}

- (void)setCustomDataBool:(BOOL)boolean forKey:(NSString *)key {
	[self setCustomData:@(boolean) forKey:key];
}

- (void)setCustomDataNumber:(NSNumber *)number forKey:(NSString *)key {
	[self setCustomData:number	forKey:key];
}

- (void)setCustomData:(NSObject<NSCoding> *)data forKey:(NSString *)key {
	if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]]) {
		return;
	}

	[self.customData setObject:data forKey:key];
	[self saveAndFlagForUpdate];
}


- (void)removeCustomDataForKey:(NSString *)key {
	[self.customData removeObjectForKey:key];
	[self saveAndFlagForUpdate];
}

@end
