//
//  ApptentiveSDK.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveVersion;


/**
 An `ApptentiveSDK` object represents a particular version/installation of the
 Apptentive SDK.
 */
@interface ApptentiveSDK : ApptentiveState

/**
 Always returns the current version of the SDK.
 */
@property (class, readonly, strong, nonatomic) ApptentiveVersion *SDKVersion;

/**
 The name of the method of distribution for the SDK (e.g. 'CocoaPods-Source').
 */
@property (class, copy, nonatomic) NSString *distributionName;

/**
 The version of the distribution method for the SDK.
 */
@property (class, strong, nonatomic) ApptentiveVersion *distributionVersion;

/**
 The SDK version of the SDK instance. Set to the value of `+SDKVersion` when
 created with `-initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) ApptentiveVersion *version;

/**
 The programming language for the SDK instance. Set to 'Objective-C' when
 created with `-initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) NSString *programmingLanguage;

/**
 The SDK Author. Set to "Apptentive, Inc." when created
 with `-initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) NSString *authorName;

/**
 The platform that the SDK targets. Set to "iOS" when created
 with `-initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) NSString *platform;

/**
 The name of the method of distribution for the SDK. Set to the value of
 `+distributionName` when created with `initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) NSString *distributionName;

/**
 The version of the distribution method for the SDK. Set to the value of
 `+distributionVersion` when created with `initWithCurrentSDK`.
 */
@property (readonly, strong, nonatomic) ApptentiveVersion *distributionVersion;

/**
 Initializes and SDK object with the values obtained by inspecting the current
 SDK.

 @return The newly-initialized SDK object.
 */
- (instancetype)initWithCurrentSDK;

@end

NS_ASSUME_NONNULL_END
