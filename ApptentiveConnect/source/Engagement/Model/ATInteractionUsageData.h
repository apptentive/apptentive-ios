//
//  ATInteractionUsageData.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATInteraction.h"


@interface ATInteractionUsageData : NSObject

@property (readonly, nonatomic) NSNumber *timeSinceInstallTotal;
@property (readonly, nonatomic) NSNumber *timeSinceInstallVersion;
@property (readonly, nonatomic) NSNumber *timeSinceInstallBuild;
@property (readonly, nonatomic) NSDate *timeAtInstallTotal;
@property (readonly, nonatomic) NSDate *timeAtInstallVersion;
@property (readonly, nonatomic) NSString *applicationVersion;
@property (readonly, nonatomic) NSString *applicationBuild;
@property (readonly, nonatomic) NSString *sdkVersion;
@property (readonly, nonatomic) NSString *sdkDistribution;
@property (readonly, nonatomic) NSString *sdkDistributionVersion;
@property (readonly, nonatomic) NSNumber *currentTime;
@property (readonly, nonatomic) NSNumber *isUpdateVersion;
@property (readonly, nonatomic) NSNumber *isUpdateBuild;
@property (readonly, nonatomic) NSDictionary *codePointInvokesTotal;
@property (readonly, nonatomic) NSDictionary *codePointInvokesVersion;
@property (readonly, nonatomic) NSDictionary *codePointInvokesBuild;
@property (readonly, nonatomic) NSDictionary *codePointInvokesTimeAgo;
@property (readonly, nonatomic) NSDictionary *interactionInvokesTotal;
@property (readonly, nonatomic) NSDictionary *interactionInvokesVersion;
@property (readonly, nonatomic) NSDictionary *interactionInvokesBuild;
@property (readonly, nonatomic) NSDictionary *interactionInvokesTimeAgo;

@property (readonly, nonatomic) NSDictionary *engagementData;

- (instancetype)initWithEngagementData:(NSDictionary *)engagementData;

- (NSDictionary *)predicateEvaluationDictionary;

// Debugging
@property (assign, nonatomic) NSTimeInterval currentTimeOffset;

@end
