//
//  ATEngagementManifestUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATExpiringUpdater.h"

@class ATEngagementManifest;

@interface ATEngagementManifestUpdater : ATExpiringUpdater

@property (readonly, nonatomic) NSDictionary *interactions;
@property (readonly, nonatomic) NSDictionary *targets;

@end
