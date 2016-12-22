//
//  ApptentiveSDK.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentiveVersion;

@interface ApptentiveSDK : ApptentiveState

@property (class, readonly, strong, nonatomic) ApptentiveVersion *SDKVersion;
@property (class, copy, nonatomic) NSString *distributionName;
@property (class, strong, nonatomic) ApptentiveVersion *distributionVersion;

@property (readonly, strong, nonatomic) ApptentiveVersion *version;
@property (readonly, strong, nonatomic) NSString *programmingLanguage;
@property (readonly, strong, nonatomic) NSString *authorName;
@property (readonly, strong, nonatomic) NSString *platform;
@property (readonly, strong, nonatomic) NSString *distributionName;
@property (readonly, strong, nonatomic) ApptentiveVersion *distributionVersion;


- (instancetype)initWithCurrentSDK;

@end
