//
//  ApptentiveJSONSerialization.h
//  Apptentive
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSInteger ApptentiveJSONDeserializationErrorCode;
extern NSInteger ApptentiveJSONSerializationErrorCode;


@interface ApptentiveJSONSerialization : NSObject

+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;
+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error;
+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
