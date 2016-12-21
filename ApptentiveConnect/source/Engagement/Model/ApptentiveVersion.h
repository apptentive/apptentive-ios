//
//  ApptentiveVersion.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/17/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@interface ApptentiveVersion : ApptentiveState

@property (readonly, nonatomic) NSInteger major;
@property (readonly, nonatomic) NSInteger minor;
@property (readonly, nonatomic) NSInteger patch;

@property (readonly, nonatomic) NSString *versionString;

- (instancetype)initWithString:(NSString *)versionString;
- (BOOL)isEqualToVersion:(ApptentiveVersion *)version;

@end
