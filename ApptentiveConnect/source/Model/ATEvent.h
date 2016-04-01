//
//  ATEvent.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATRecord.h"

#import "ApptentiveJSONModel.h"
#import "ATRecordRequestTask.h"


@interface ATEvent : ATRecord <ApptentiveJSONModel, ATRequestTaskProvider>

@property (strong, nonatomic) NSString *pendingEventID;
@property (strong, nonatomic) NSData *dictionaryData;
@property (strong, nonatomic) NSString *label;

+ (instancetype)newInstanceWithLabel:(NSString *)label;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
