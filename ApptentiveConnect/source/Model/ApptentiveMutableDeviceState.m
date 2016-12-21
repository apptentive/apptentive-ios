//
//  ApptentiveCustomData.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableDeviceState.h"
#import "ApptentiveCustomDataState.h"

@interface ApptentiveMutableDeviceState ()

@property (strong, nonatomic) NSMutableDictionary *mutableCustomData;

@end

@implementation ApptentiveMutableDeviceState

- (instancetype)initWithCustomDataState:(ApptentiveCustomDataState *)state {
	self = [super init];

	if (self) {
		_mutableCustomData = [state.customData mutableCopy] ?: [NSMutableDictionary dictionary];
	}

	return self;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableCustomData = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)addCustomData:(NSObject<NSCoding> *)customData withKey:(NSString *)key {
	// TODO: verify that it's the right kind of object
	[self.mutableCustomData setObject:customData forKey:key];
}

- (void)removeCustomDataWithKey:(NSString *)key {
	[self.mutableCustomData removeObjectForKey:key];
}

- (NSDictionary *)customData {
	return self.mutableCustomData;
}

@end
