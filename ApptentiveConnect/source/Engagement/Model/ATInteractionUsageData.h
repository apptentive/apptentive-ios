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

@property (nonatomic, retain) NSNumber *timeSinceInstallTotal;
@property (nonatomic, retain) NSNumber *timeSinceInstallVersion;
@property (nonatomic, retain) NSNumber *timeSinceInstallBuild;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationBuild;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *sdkDistribution;
@property (nonatomic, copy) NSString *sdkDistributionVersion;
@property (nonatomic, retain) NSNumber *currentTime;
@property (nonatomic, retain) NSNumber *isUpdateVersion;
@property (nonatomic, retain) NSNumber *isUpdateBuild;
@property (nonatomic, retain) NSDictionary *codePointInvokesTotal;
@property (nonatomic, retain) NSDictionary *codePointInvokesVersion;
@property (nonatomic, retain) NSDictionary *codePointInvokesBuild;
@property (nonatomic, retain) NSDictionary *codePointInvokesTimeAgo;
@property (nonatomic, retain) NSDictionary *interactionInvokesTotal;
@property (nonatomic, retain) NSDictionary *interactionInvokesVersion;
@property (nonatomic, retain) NSDictionary *interactionInvokesBuild;
@property (nonatomic, retain) NSDictionary *interactionInvokesTimeAgo;

+ (ATInteractionUsageData *)usageData;

- (NSDictionary *)predicateEvaluationDictionary;

@end
