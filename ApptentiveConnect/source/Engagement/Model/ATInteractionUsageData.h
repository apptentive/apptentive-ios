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

@property (nonatomic, retain) ATInteraction *interaction;
@property (nonatomic, retain) NSNumber *daysSinceInstall;
@property (nonatomic, retain) NSNumber *daysSinceUpgrade;
@property (nonatomic, retain) NSString *applicationVersion;
@property (nonatomic, retain) NSDictionary *codePointInvokesTotal;
@property (nonatomic, retain) NSDictionary *codePointInvokesVersion;
@property (nonatomic, retain) NSDictionary *interactionInvokesTotal;
@property (nonatomic, retain) NSDictionary *interactionInvokesVersion;

- (id)initWithInteraction:(ATInteraction *)interaction;
+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction;
+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction
								   daysSinceInstall:(NSNumber *)daysSinceInstall
								   daysSinceUpgrade:(NSNumber *)daysSinceUpgrade
								 applicationVersion:(NSString *)applicationVersion
							  codePointInvokesTotal:(NSDictionary *)codePointInvokesTotal
							codePointInvokesVersion:(NSDictionary *)codePointInvokesVersion
							interactionInvokesTotal:(NSDictionary *)interactionInvokesTotal
						  interactionInvokesVersion:(NSDictionary *)interactionInvokesVersion;

- (NSDictionary *)predicateEvaluationDictionary;

@end
