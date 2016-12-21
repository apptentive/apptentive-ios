//
//  ApptentiveInteractionUsageData.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveInteraction.h"

@class ApptentiveConsumerData;

@interface ApptentiveInteractionUsageData : NSObject

@property (readonly, strong, nonatomic) ApptentiveConsumerData *data;

+ (instancetype)usageDataWithConsumerData:(ApptentiveConsumerData *)data;

- (instancetype)initWithConsumerData:(ApptentiveConsumerData *)data;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
