//
//  ApptentiveJWT.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveJWT : NSObject

@property (copy, nonatomic, readonly) NSString *alg;
@property (copy, nonatomic, readonly) NSString *type;
@property (copy, nonatomic, readonly) NSDictionary *payload;

- (nullable instancetype)initWithAlg:(NSString *)alg type:(NSString *)type payload:(NSDictionary *)payload;

+ (nullable instancetype)JWTWithContentOfString:(NSString *)string error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
