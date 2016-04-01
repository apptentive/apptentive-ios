//
//  ATEvent.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ApptentiveRecord.h"

#import "ApptentiveJSONModel.h"
#import "ApptentiveRecordRequestTask.h"


@interface ApptentiveEvent : ApptentiveRecord <ApptentiveJSONModel, ATRequestTaskProvider>

@property (strong, nonatomic) NSString *pendingEventID;
@property (strong, nonatomic) NSData *dictionaryData;
@property (strong, nonatomic) NSString *label;

+ (instancetype)newInstanceWithLabel:(NSString *)label;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
