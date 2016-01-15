//
//  ATMessageSender.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ATMessage;


@interface ATMessageSender : NSManagedObject

@property (strong, nonatomic) NSString *apptentiveID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *emailAddress;
@property (strong, nonatomic) NSString *profilePhotoURL;
@property (strong, nonatomic) NSSet *sentMessages;
@property (strong, nonatomic) NSSet *receivedMessages;

+ (ATMessageSender *)findSenderWithID:(NSString *)apptentiveID;
+ (ATMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json;
- (NSDictionary *)apiJSON;
@end


@interface ATMessageSender (CoreDataGeneratedAccessors)

- (void)addSentMessagesObject:(ATMessage *)value;
- (void)removeSentMessagesObject:(ATMessage *)value;
- (void)addSentMessages:(NSSet *)values;
- (void)removeSentMessages:(NSSet *)values;

- (void)addReceivedMessagesObject:(ATMessage *)value;
- (void)removeReceivedMessagesObject:(ATMessage *)value;
- (void)addReceivedMessages:(NSSet *)values;
- (void)removeReceivedMessages:(NSSet *)values;

@end
