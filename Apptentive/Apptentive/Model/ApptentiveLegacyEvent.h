//
//  ApptentiveLegacyEvent.h
//  Apptentive
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;


/**
 Represents legacy event objects waiting to be sent in Core Data.
 */
@interface ApptentiveLegacyEvent : ApptentiveRecord

@property (copy, nonatomic) NSString *pendingEventID;
@property (copy, nonatomic) NSData *dictionaryData;
@property (copy, nonatomic) NSString *label;

/**
 Migrates legacy event objects waiting to be sent in Core Data into
 `ApptentiveSerialRequest` objects.

 @param context The managed object context to use to migrate events.
 */
+ (void)enqueueUnsentEventsInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation;
@end

NS_ASSUME_NONNULL_END
