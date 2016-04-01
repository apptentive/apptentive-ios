//
//  ATMetric.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATMetric.h"
#import "Apptentive_Private.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATWebClient+Metrics.h"

#define kATMetricStorageVersion 1


@implementation ATMetric {
	NSMutableDictionary *_info;
}

- (id)init {
	if ((self = [super init])) {
		_info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMetricStorageVersion) {
			self.name = [coder decodeObjectForKey:@"name"];
			NSDictionary *d = [coder decodeObjectForKey:@"info"];
			if (_info) {
				_info = nil;
			}
			if (d != nil) {
				_info = [d mutableCopy];
			} else {
				_info = [[NSMutableDictionary alloc] init];
			}
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInt:kATMetricStorageVersion forKey:@"version"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.info forKey:@"info"];
}


- (void)setValue:(id)value forKey:(NSString *)key {
	[_info setValue:value forKey:key];
}

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary {
	if (dictionary != nil) {
		[_info addEntriesFromDictionary:dictionary];
	}
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];

	if (self.name) [d setObject:self.name forKey:@"record[metric][event]"];

	if (self.info) {
		for (NSString *key in self.info) {
			NSString *recordKey = [NSString stringWithFormat:@"record[metric][data][%@]", key];
			NSObject *value = [self.info objectForKey:key];
			if ([value isKindOfClass:[NSDate class]]) {
				value = [ATUtilities stringRepresentationOfDate:(NSDate *)value];
			}
			[d setObject:value forKey:recordKey];
		}
	}
	return d;
}

- (ATAPIRequest *)requestForSendingRecord {
	return [[Apptentive sharedConnection].webClient requestForSendingMetric:self];
}
@end
