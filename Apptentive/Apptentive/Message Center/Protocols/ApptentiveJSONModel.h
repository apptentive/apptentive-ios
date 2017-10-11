//
//  ApptentiveJSONModel.h
//  Apptentive
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ApptentiveJSONModel <NSObject>

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json;
- (void)updateWithJSON:(NSDictionary *)json;
- (nullable NSDictionary *)apiJSON;

@end

NS_ASSUME_NONNULL_END
