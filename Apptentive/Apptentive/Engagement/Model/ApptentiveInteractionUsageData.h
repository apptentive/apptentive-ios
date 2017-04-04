//
//  ApptentiveInteractionUsageData.h
//  Apptentive
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveInteraction.h"

@class ApptentiveConversation;


@interface ApptentiveInteractionUsageData : NSObject

@property (readonly, strong, nonatomic) ApptentiveConversation *conversation;

+ (instancetype)usageDataWithConversation:(ApptentiveConversation *)conversation;

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
