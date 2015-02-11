//
//  ATInteractionInvocation.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATInteractionUsageData;

@interface ATInteractionInvocation : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy) NSString *interactionID;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, retain) NSDictionary *criteria;

+ (ATInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary;
+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray;

- (BOOL)isValid;

- (BOOL)criteriaAreMet;
- (BOOL)criteriaAreMetForUsageData:(ATInteractionUsageData *)usageData;

- (NSPredicate *)criteriaPredicate;
+ (NSPredicate *)predicateForCriteria:(NSString *)criteria operatorExpression:(NSDictionary *)operatorExpression hasError:(BOOL *)hasError;
+ (NSPredicate *)predicateForInteractionCriteria:(NSDictionary *)interactionCriteria hasError:(BOOL *)hasError;

@end
