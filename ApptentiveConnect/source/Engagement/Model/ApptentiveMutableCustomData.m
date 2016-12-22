//
//  ApptentiveMutableCustomData.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMutableCustomData.h"
#import "ApptentiveCustomData.h"

@interface ApptentiveMutableCustomData ()

@property (strong, nonatomic) NSMutableDictionary *mutableCustomData;

@end

@implementation ApptentiveMutableCustomData

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableCustomData = [NSMutableDictionary dictionary];
	}
	return self;
}

- (instancetype)initWithCustomData:(ApptentiveCustomData *)customDataContainer {
	self = [super init];

	if (self) {
		_mutableCustomData = [customDataContainer.customData mutableCopy] ?: [NSMutableDictionary dictionary];
		_identifier = customDataContainer.identifier;
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
