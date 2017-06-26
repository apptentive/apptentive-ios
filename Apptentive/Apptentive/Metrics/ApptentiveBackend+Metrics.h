//
//  ApptentiveMetrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"

@class ApptentiveMetric;


@interface ApptentiveBackend (Metrics)

- (void)startMonitoringAppLifecycleMetrics;
- (void)conversation:(ApptentiveConversation *)conversation addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;

@end
