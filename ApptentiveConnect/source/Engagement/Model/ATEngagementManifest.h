//
//  ATEngagementManifest.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATExpiringUpdater.h"

@interface ATEngagementManifest : NSObject <ATUpdatable>

- (instancetype)initWithTargets:(NSDictionary *)targets interactions:(NSDictionary *)interactions;

@property (readonly, nonatomic) NSDictionary *targets;
@property (readonly, nonatomic) NSDictionary *interactions;

@end
