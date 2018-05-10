//
//  ApptentiveTarget.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveClause;


@interface ApptentiveTarget : NSObject <NSSecureCoding>

@property (readonly, nonatomic) NSString *interactionIdentifier;
@property (readonly, nonatomic) ApptentiveClause *criteria;

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
