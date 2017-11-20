//
//  NSDictionary+Apptentive.h
//  Apptentive
//
//  Created by Andrew Wooster on 2/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSDictionary (Apptentive)
/*! Doesn't return NSNull objects. */
- (nullable id)at_safeObjectForKey:(id)aKey;
@end

NS_ASSUME_NONNULL_END
