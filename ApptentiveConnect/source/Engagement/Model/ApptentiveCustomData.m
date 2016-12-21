//
//  ApptentiveCustomData.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

static NSString * const CustomDataKey = @"customData";
static NSString * const IdentifierKey = @"identifier";

@interface ApptentiveCustomData ()

@property (strong, nonatomic) NSMutableDictionary<NSString *,NSObject<NSCoding> *> *mutableCustomData;

@end

@implementation ApptentiveCustomData

- (instancetype)init {
	self = [super init];

	if (self) {
		_mutableCustomData = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (instancetype)initWithCustomData:(NSDictionary *)customData identifier:(NSString *)identifier {
	self = [super init];

	if (self) {
		_mutableCustomData = [customData mutableCopy];
		_identifier = identifier;
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_mutableCustomData = [aDecoder decodeObjectOfClass:[NSMutableDictionary class] forKey:CustomDataKey];
		_identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.mutableCustomData forKey:CustomDataKey];
	[aCoder encodeObject:self.identifier forKey:IdentifierKey];
}

- (NSDictionary<NSString *,NSObject<NSCoding> *> *)customData {
	return [self.mutableCustomData copy];
}

@end

@implementation ApptentiveCustomData (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{ @"custom_data": NSStringFromSelector(@selector(customData)) };
}

@end
