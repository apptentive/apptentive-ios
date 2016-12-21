//
//  ApptentiveDevice.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

@class ApptentiveVersion, ApptentiveMutableDevice;

@interface ApptentiveDevice : ApptentiveCustomData

@property (readonly, strong, nonatomic) NSUUID *UUID;
@property (readonly, strong, nonatomic) NSString *OSName;
@property (readonly, strong, nonatomic) ApptentiveVersion *OSVersion;
@property (readonly, strong, nonatomic) NSString *OSBuild;
@property (readonly, strong, nonatomic) NSString *hardware;
@property (readonly, strong, nonatomic) NSString *carrier;
@property (readonly, strong, nonatomic) NSString *contentSizeCategory;
@property (readonly, strong, nonatomic) NSString *localeRaw;
@property (readonly, strong, nonatomic) NSString *localeCountryCode;
@property (readonly, strong, nonatomic) NSString *localeLanguageCode;
@property (readonly, assign, nonatomic) NSInteger UTCOffset;
@property (readonly, strong, nonatomic) NSDictionary *integrationConfiguration;

- (instancetype)initWithCurrentDevice;
- (instancetype)initWithMutableDevice:(ApptentiveMutableDevice *)mutableDevice;

@end
