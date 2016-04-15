//
//  ApptentiveInteractionUsageData.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionUsageData : NSObject

@property (strong, nonatomic) NSNumber *timeSinceInstallTotal;
@property (strong, nonatomic) NSNumber *timeSinceInstallVersion;
@property (strong, nonatomic) NSNumber *timeSinceInstallBuild;
@property (strong, nonatomic) NSDate *timeAtInstallTotal;
@property (strong, nonatomic) NSDate *timeAtInstallVersion;
@property (copy, nonatomic) NSString *applicationVersion;
@property (copy, nonatomic) NSString *applicationBuild;
@property (copy, nonatomic) NSString *sdkVersion;
@property (copy, nonatomic) NSString *sdkDistribution;
@property (copy, nonatomic) NSString *sdkDistributionVersion;
@property (strong, nonatomic) NSNumber *currentTime;
@property (strong, nonatomic) NSNumber *isUpdateVersion;
@property (strong, nonatomic) NSNumber *isUpdateBuild;
@property (strong, nonatomic) NSDictionary *codePointInvokesTotal;
@property (strong, nonatomic) NSDictionary *codePointInvokesVersion;
@property (strong, nonatomic) NSDictionary *codePointInvokesBuild;
@property (strong, nonatomic) NSDictionary *codePointInvokesTimeAgo;
@property (strong, nonatomic) NSDictionary *interactionInvokesTotal;
@property (strong, nonatomic) NSDictionary *interactionInvokesVersion;
@property (strong, nonatomic) NSDictionary *interactionInvokesBuild;
@property (strong, nonatomic) NSDictionary *interactionInvokesTimeAgo;

+ (ApptentiveInteractionUsageData *)usageData;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
