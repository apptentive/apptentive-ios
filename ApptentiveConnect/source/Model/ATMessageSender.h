//
//  ATMessageSender.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ATAbstractMessage;

@interface ATMessageSender : NSManagedObject

@property (nonatomic, strong) NSString *apptentiveID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *emailAddress;
@property (nonatomic, strong) NSString *profilePhotoURL;
@property (nonatomic, strong) NSSet *sentMessages;
@property (nonatomic, strong) NSSet *receivedMessages;

+ (ATMessageSender *)findSenderWithID:(NSString *)apptentiveID;
+ (ATMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json;
- (NSDictionary *)apiJSON;
@end

@interface ATMessageSender (CoreDataGeneratedAccessors)

- (void)addSentMessagesObject:(ATAbstractMessage *)value;
- (void)removeSentMessagesObject:(ATAbstractMessage *)value;
- (void)addSentMessages:(NSSet *)values;
- (void)removeSentMessages:(NSSet *)values;

- (void)addReceivedMessagesObject:(ATAbstractMessage *)value;
- (void)removeReceivedMessagesObject:(ATAbstractMessage *)value;
- (void)addReceivedMessages:(NSSet *)values;
- (void)removeReceivedMessages:(NSSet *)values;

@end
