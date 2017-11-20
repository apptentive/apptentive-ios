//
//  ApptentiveInteractionUsageData.h
//  Apptentive
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteraction.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;


@interface ApptentiveInteractionUsageData : NSObject

@property (readonly, strong, nonatomic) ApptentiveConversation *conversation;

+ (instancetype)usageDataWithConversation:(ApptentiveConversation *)conversation;

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
