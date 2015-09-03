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

#import "ATJSONModel.h"
#import "ATRecordRequestTask.h"

@interface ATEvent : ATRecord <ATJSONModel, ATRequestTaskProvider>

@property (nonatomic, strong) NSString *pendingEventID;
@property (nonatomic, strong) NSData *dictionaryData;
@property (nonatomic, strong) NSString *label;

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
