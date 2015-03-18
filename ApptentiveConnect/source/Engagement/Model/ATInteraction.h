//
//  ATInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ATInteractionUsageData;

typedef NS_ENUM(NSInteger, ATInteractionType){
	ATInteractionTypeUnknown,
	ATInteractionTypeUpgradeMessage,
	ATInteractionTypeEnjoymentDialog,
	ATInteractionTypeRatingDialog,
	ATInteractionTypeFeedbackDialog,
	ATInteractionTypeMessageCenter,
	ATInteractionTypeAppStoreRating,
	ATInteractionTypeSurvey,
	ATInteractionTypeTextModal,
	ATInteractionTypeNavigateToLink,
};

@interface ATInteraction : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, retain) NSDictionary *configuration;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *vendor;

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary;

// Used to engage local and app events
+ (ATInteraction *)localAppInteraction;
+ (ATInteraction *)apptentiveAppInteraction;

- (ATInteractionType)interactionType;

- (NSString *)codePointForEvent:(NSString *)event;

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController;
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo;
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;

@end
