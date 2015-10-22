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

@property (nonatomic, strong) NSNumber *timeSinceInstallTotal;
@property (nonatomic, strong) NSNumber *timeSinceInstallVersion;
@property (nonatomic, strong) NSNumber *timeSinceInstallBuild;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationBuild;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *sdkDistribution;
@property (nonatomic, copy) NSString *sdkDistributionVersion;
@property (nonatomic, strong) NSNumber *currentTime;
@property (nonatomic, strong) NSNumber *isUpdateVersion;
@property (nonatomic, strong) NSNumber *isUpdateBuild;
@property (nonatomic, strong) NSDictionary *codePointInvokesTotal;
@property (nonatomic, strong) NSDictionary *codePointInvokesVersion;
@property (nonatomic, strong) NSDictionary *codePointInvokesBuild;
@property (nonatomic, strong) NSDictionary *codePointInvokesTimeAgo;
@property (nonatomic, strong) NSDictionary *interactionInvokesTotal;
@property (nonatomic, strong) NSDictionary *interactionInvokesVersion;
@property (nonatomic, strong) NSDictionary *interactionInvokesBuild;
@property (nonatomic, strong) NSDictionary *interactionInvokesTimeAgo;

+ (ATInteractionUsageData *)usageData;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
