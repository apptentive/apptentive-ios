//
//  ApptentiveCustomData.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableDevice.h"
#import "ApptentiveCustomData.h"
#import "ApptentiveDevice.h"

@interface ApptentiveMutableDevice ()

@property (strong, nonatomic) NSMutableDictionary *mutableCustomData;

@end

@implementation ApptentiveMutableDevice

- (instancetype)initWithDevice:(ApptentiveDevice *)device {
	return [self initWithCustomData:device];
}

- (instancetype)initWithCustomData:(ApptentiveCustomData *)customData {
	self = [super init];

	if (self) {
		_mutableCustomData = [customData.customData mutableCopy] ?: [NSMutableDictionary dictionary];
		_identifier = customData.identifier;
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

- (void)addCustomString:(NSString *)string withKey:(NSString *)key {
	[self.mutableCustomData setObject:string forKey:key];
}

- (void)addCustomNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.mutableCustomData setObject:number forKey:key];
}

- (void)addCustomBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.mutableCustomData setObject:@(boolValue) forKey:key];
}

- (void)removeCustomValueWithKey:(NSString *)key {
	[self.mutableCustomData removeObjectForKey:key];
}

- (NSDictionary *)customData {
	return [self.mutableCustomData copy];
}

@end
