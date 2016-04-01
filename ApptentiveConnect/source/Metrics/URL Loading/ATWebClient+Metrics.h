//
//  ATWebClient+Metrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveWebClient.h"

@class ApptentiveAPIRequest, ATMetric, ATEvent;


@interface ApptentiveWebClient (Metrics)
- (ApptentiveAPIRequest *)requestForSendingMetric:(ATMetric *)metric;
- (ApptentiveAPIRequest *)requestForSendingEvent:(ATEvent *)event;
@end
