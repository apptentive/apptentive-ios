//
//  ApptentiveInteractionInvocation.h
//  Apptentive
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveInteractionUsageData, ApptentiveConversation;


@interface ApptentiveInteractionInvocation : NSObject <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *interactionID;
@property (assign, nonatomic) NSInteger priority;
@property (copy, nonatomic) NSDictionary *criteria;

+ (ApptentiveInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary;
+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray;

- (BOOL)criteriaAreMetForConversation:(ApptentiveConversation *)data;

- (NSPredicate *)criteriaPredicate;

@end
