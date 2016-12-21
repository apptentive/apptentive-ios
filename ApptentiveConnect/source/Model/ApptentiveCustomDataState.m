//
//  ApptentiveCustomDataState.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveCustomDataState.h"

NSString * const CustomDataKey = @"customData";

@implementation ApptentiveCustomDataState

- (instancetype)init {
	self = [super init];

	if (self) {
		_customData = [[NSDictionary alloc] init];
	}
	
	return self;
}

- (instancetype)initWithCustomData:(NSDictionary *)customData {
	self = [super init];

	if (self) {
		_customData = customData;
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_customData = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:CustomDataKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.customData forKey:CustomDataKey];
}

@end

@implementation ApptentiveCustomDataState (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{ @"custom_data": NSStringFromSelector(@selector(customData)) };
}

- (NSDictionary *)dictionaryForJSONKeyPropertyMapping:(NSDictionary *)JSONKeyPropertyMapping {
	NSMutableDictionary *result;

	for (NSString *JSONKey in JSONKeyPropertyMapping) {
		NSString *propertyName = JSONKeyPropertyMapping[JSONKey];

		NSObject *value = [self valueForKeyPath:propertyName];

		if (value) {
			result[JSONKey] = value;
		}
	}

	return result;
}

- (NSDictionary *)JSONDictionary {
	return [self dictionaryForJSONKeyPropertyMapping:[[self class] JSONKeyPathMapping]];
}

@end
