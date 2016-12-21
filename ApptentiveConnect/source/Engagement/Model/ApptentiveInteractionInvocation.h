//
//  ApptentiveInteractionInvocation.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveInteractionUsageData, ApptentiveConsumerData;


@interface ApptentiveInteractionInvocation : NSObject <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *interactionID;
@property (assign, nonatomic) NSInteger priority;
@property (copy, nonatomic) NSDictionary *criteria;

+ (ApptentiveInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary;
+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray;

- (BOOL)criteriaAreMetForConsumerData:(ApptentiveConsumerData *)data;


- (NSPredicate *)criteriaPredicate;

@end
