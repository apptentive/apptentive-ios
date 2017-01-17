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
	if (string != nil && key != nil) {
		[self.mutableCustomData setObject:string forKey:key];
	} else {
		ApptentiveLogError(@"Attempting to add custom data string with nil key and/or value");
	}
}

- (void)addCustomNumber:(NSNumber *)number withKey:(NSString *)key {
	if (number != nil && key != nil) {
		[self.mutableCustomData setObject:number forKey:key];
	} else {
		ApptentiveLogError(@"Attempting to add custom data number with nil key and/or value");
	}
}

- (void)addCustomBool:(BOOL)boolValue withKey:(NSString *)key {
	if (key != nil) {
		[self.mutableCustomData setObject:@(boolValue) forKey:key];
	} else {
		ApptentiveLogError(@"Attempting to add custom data boolean with nil key");
	}
}

- (void)removeCustomValueWithKey:(NSString *)key {
	if (key != nil) {
		[self.mutableCustomData removeObjectForKey:key];
	} else {
		ApptentiveLogError(@"Attempting to remove custom data with nil key");
	}
}

- (NSDictionary *)customData {
	return [self.mutableCustomData copy];
}

@end
