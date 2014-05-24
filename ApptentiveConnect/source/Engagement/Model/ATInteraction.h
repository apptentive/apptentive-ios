//
//  ATInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATInteractionUsageData;

typedef NS_ENUM(NSInteger, ATInteractionType){
	ATInteractionTypeUnknown,
	ATInteractionTypeUpgradeMessage,
	ATInteractionTypeEnjoymentDialog,
	ATInteractionTypeRatingDialog,
	ATInteractionTypeFeedbackDialog,
	ATInteractionTypeMessageCenter,
	ATInteractionTypeAppStoreRating,
	ATInteractionTypeSurvey
};

@interface ATInteraction : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, retain) NSDictionary *configuration;
@property (nonatomic, retain) NSDictionary *criteria;
@property (nonatomic, copy) NSString *version;

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary;

- (ATInteractionType)interactionType;

- (BOOL)isValid;

- (ATInteractionUsageData *)usageData;
- (BOOL)criteriaAreMet;
- (BOOL)criteriaAreMetForUsageData:(ATInteractionUsageData *)usageData;

- (NSPredicate *)criteriaPredicate;
+ (NSPredicate *)predicateForInteractionCriteria:(NSDictionary *)interactionCriteria hasError:(BOOL *)hasError;
@end
