//
//  ApptentiveMetrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "ATInteraction.h"

@class ATMetric;

@interface ApptentiveMetrics : NSObject {
@private
	BOOL metricsEnabled;
}

+ (ApptentiveMetrics *)sharedMetrics;

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo;
- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;
- (void)addMetricWithName:(NSString *)name fromInteraction:(ATInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;

- (BOOL)upgradeLegacyMetric:(ATMetric *)metric;

@end

