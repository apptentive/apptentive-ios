//
//  ApptentiveLegacyMessageSender.h
//  Apptentive
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ApptentiveLegacyMessage;


@interface ApptentiveLegacyMessageSender : NSManagedObject

@property (copy, nonatomic) NSString *apptentiveID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;
@property (copy, nonatomic) NSString *profilePhotoURL;
@property (strong, nonatomic) NSSet *sentMessages;
@property (strong, nonatomic) NSSet *receivedMessages;

+ (ApptentiveLegacyMessageSender *)findSenderWithID:(NSString *)apptentiveID inContext:(NSManagedObjectContext *)context;
+ (ApptentiveLegacyMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context;
- (NSDictionary *)apiJSON;
@end


@interface ApptentiveLegacyMessageSender (CoreDataGeneratedAccessors)

- (void)addSentMessagesObject:(ApptentiveLegacyMessage *)value;
- (void)removeSentMessagesObject:(ApptentiveLegacyMessage *)value;
- (void)addSentMessages:(NSSet *)values;
- (void)removeSentMessages:(NSSet *)values;

- (void)addReceivedMessagesObject:(ApptentiveLegacyMessage *)value;
- (void)removeReceivedMessagesObject:(ApptentiveLegacyMessage *)value;
- (void)addReceivedMessages:(NSSet *)values;
- (void)removeReceivedMessages:(NSSet *)values;

@end
