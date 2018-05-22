//
//  ApptentiveLogTag.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveLogTag : NSObject

@property (nonatomic, readonly) NSString *name;

+ (instancetype)logTagWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;

+ (ApptentiveLogTag *)conversationTag;
+ (ApptentiveLogTag *)networkTag;
+ (ApptentiveLogTag *)payloadTag;
+ (ApptentiveLogTag *)utilityTag;
+ (ApptentiveLogTag *)storageTag;
+ (ApptentiveLogTag *)logMonitorTag;
+ (ApptentiveLogTag *)criteriaTag;
+ (ApptentiveLogTag *)interactionsTag;
+ (ApptentiveLogTag *)pushTag;
+ (ApptentiveLogTag *)messagesTag;
+ (ApptentiveLogTag *)apptimizeTag;

@end

NS_ASSUME_NONNULL_END
