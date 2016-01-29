//
//  ATExpiry.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATExpiry : NSObject <NSCoding>

- (instancetype)initWithExpirationDate:(NSDate *)expirationDate appBuild:(NSString *)appBuild SDKVersion:(NSString *)SDKVersion;

@property (readonly, nonatomic) NSDate *expirationDate;
@property (strong, nonatomic) NSString *SDKVersion;
@property (strong, nonatomic) NSString *appBuild;

@property (assign, nonatomic) NSTimeInterval maxAge;
@property (readonly, nonatomic, getter=isExpired) BOOL expired;

@end
