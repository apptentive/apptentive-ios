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

@property (readonly, strong, nonatomic) ApptentiveSession *session;

+ (instancetype)usageDataWithSession:(ApptentiveSession *)session;

- (instancetype)initWithSession:(ApptentiveSession *)session;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
