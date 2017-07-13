//
//  ApptentiveAppInstall.h
//  Apptentive
//
//  Created by Frank Schmitt on 7/13/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentivePerson, ApptentiveDevice, ApptentiveSDK, ApptentiveAppRelease;
@protocol ApptentiveAppInstall;

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveAppInstall : NSObject <ApptentiveAppInstall>

- (instancetype)initWithToken:(nullable NSString *)token identifier:(nullable NSString *)identifier;

@end


@protocol ApptentiveAppInstall <NSObject>

@property (readonly, nullable, nonatomic) NSString *token;
@property (readonly, nullable, nonatomic) NSString *identifier;

@property (readonly, nonatomic) ApptentivePerson *person;
@property (readonly, nonatomic) ApptentiveDevice *device;
@property (readonly, nonatomic) ApptentiveSDK *SDK;
@property (readonly, nonatomic) ApptentiveAppRelease *appRelease;

@end

NS_ASSUME_NONNULL_END
