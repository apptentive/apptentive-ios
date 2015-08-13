//
//  ATAbstractMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATJSONModel.h"
#import "ATRecord.h"

typedef NS_ENUM(NSInteger, ATPendingMessageState) {
	ATPendingMessageStateNone = -1,
	ATPendingMessageStateComposing = 0,
	ATPendingMessageStateSending,
	ATPendingMessageStateConfirmed,
	ATPendingMessageStateError
};

@class ATMessageDisplayType, ATMessageSender;

@interface ATAbstractMessage : ATRecord <ATJSONModel>

@property (nonatomic, strong) NSString *pendingMessageID;
@property (nonatomic, strong) NSNumber *pendingState;
@property (nonatomic, strong) NSNumber *priority;
@property (nonatomic, strong) NSNumber *seenByUser;
@property (nonatomic, strong) NSNumber *sentByUser;
@property (nonatomic, strong) NSNumber *errorOccurred;
@property (nonatomic, strong) NSString *errorMessageJSON;
@property (nonatomic, strong) ATMessageSender *sender;
@property (nonatomic, strong) NSSet *displayTypes;
@property (nonatomic, strong) NSData *customData;
@property (nonatomic, strong) NSNumber *hidden;

+ (ATAbstractMessage *)findMessageWithID:(NSString *)apptentiveID;
+ (ATAbstractMessage *)findMessageWithPendingID:(NSString *)pendingID;
- (NSArray *)errorsFromErrorMessage;
@end

@interface ATAbstractMessage (CoreDataGeneratedAccessors)

- (void)addDisplayTypesObject:(ATMessageDisplayType *)value;
- (void)removeDisplayTypesObject:(ATMessageDisplayType *)value;
- (void)addDisplayTypes:(NSSet *)values;
- (void)removeDisplayTypes:(NSSet *)values;

- (void)setCustomDataValue:(id)value forKey:(NSString *)key;
- (void)addCustomDataFromDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryForCustomData;
- (NSData *)dataForDictionary:(NSDictionary *)dictionary;

- (void)markAsRead;

@end
