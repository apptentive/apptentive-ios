//
//  ATRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATAPIRequest;

@interface ATRecord : NSObject <NSCoding>
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *model;
@property (nonatomic, retain) NSString *os_version;
@property (nonatomic, retain) NSString *carrier;
@property (nonatomic, retain) NSDate *date;

- (NSString *)formattedDate:(NSDate *)aDate;

- (NSDictionary *)apiDictionary;
- (ATAPIRequest *)requestForSendingRecord;
@end
