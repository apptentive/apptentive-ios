//
//  ApptentiveComparisonClause.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClause.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;

typedef BOOL (^ComparisonBlock)(NSObject *value, NSObject * _Nullable parameter);


@interface ApptentiveComparisonClause : ApptentiveClause

+ (ApptentiveClause *)comparisonClauseWithField:(NSString *)key comparisons:(NSDictionary *)comparisons;

+ (NSDictionary *)operators;

- (instancetype)initWithField:(NSString *)field comparisons:(NSDictionary *)comparisons;

@property (strong, nonatomic) NSString *field;
@property (strong, nonatomic) NSDictionary *comparisons;

- (NSObject *)valueInConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
