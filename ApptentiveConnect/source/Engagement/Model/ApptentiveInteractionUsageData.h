//
//  ApptentiveInteractionUsageData.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveInteraction.h"

@class ApptentiveSession;

@interface ApptentiveInteractionUsageData : NSObject

@property (readonly, strong, nonatomic) ApptentiveSession *data;

+ (instancetype)usageDataWithConsumerData:(ApptentiveSession *)data;

- (instancetype)initWithConsumerData:(ApptentiveSession *)data;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
