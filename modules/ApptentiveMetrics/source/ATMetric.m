//
//  ATMetric.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATMetric.h"

#define kATMetricStorageVersion 1

@implementation ATMetric
@synthesize name, date, info;

- (id)init {
	if ((self = [super init])) {
		info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATMetricStorageVersion) {
            self.name = [coder decodeObjectForKey:@"name"];
            self.date = [coder decodeObjectForKey:@"date"];
            NSDictionary *d = [coder decodeObjectForKey:@"info"];
			if (d != nil) {
				info = [d mutableCopy];
			} else {
				info = [[NSMutableDictionary alloc] init];
			}
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATMetricStorageVersion forKey:@"version"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.info forKey:@"info"];
}

- (void)dealloc {
	[name release], name = nil;
	[date release], date = nil;
	[info release], info = nil;
	[super dealloc];
}

- (void)setValue:(id)value forKey:(NSString *)key {
	[info setValue:value forKey:key];
}

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary {
	if (dictionary != nil) {
		[info addEntriesFromDictionary:dictionary];
	}
}
@end
