//
//  ApptentiveLegacyEvent.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

@interface ApptentiveLegacyEvent : ApptentiveRecord

@property (copy, nonatomic) NSString *pendingEventID;
@property (copy, nonatomic) NSData *dictionaryData;
@property (copy, nonatomic) NSString *label;

+ (void)enqueueUnsentEventsInContext:(NSManagedObjectContext *)context;

@end
