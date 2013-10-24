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
@property (nonatomic, retain) NSString *codePoint;
@property (nonatomic, retain) NSNumber *daysSinceInstall;
@property (nonatomic, retain) NSNumber *daysSinceUpgrade;
@property (nonatomic, retain) NSString *applicationVersion;
@property (nonatomic, retain) NSNumber *codePointInvokesTotal;
@property (nonatomic, retain) NSNumber *codePointInvokesVersion;
@property (nonatomic, retain) NSNumber *interactionInvokesTotal;
@property (nonatomic, retain) NSNumber *interactionInvokesVersion;

- (id)initWithInteraction:(ATInteraction *)interaction atCodePoint:(NSString *)codePoint;
+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction atCodePoint:(NSString *)codePoint;
+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction
							  atCodePoint:(NSString *)codePoint
						 daysSinceInstall:(NSNumber *)daysSinceInstall
						 daysSinceUpgrade:(NSNumber *)daysSinceUpgrade
					   applicationVersion:(NSString *)applicationVersion
					codePointInvokesTotal:(NSNumber *)codePointInvokesTotal
				  codePointInvokesVersion:(NSNumber *)codePointInvokesVersion
				  interactionInvokesTotal:(NSNumber *)interactionInvokesTotal
				interactionInvokesVersion:(NSNumber *)interactionInvokesVersion;

- (NSDictionary *)predicateEvaluationDictionary;

@end
