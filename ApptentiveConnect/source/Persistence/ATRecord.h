//
//  ATRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATAPIRequest;

@interface ATRecord : NSObject <NSCoding> {
@private
	NSString *uuid;
	NSString *model;
	NSString *os_version;
	NSString *carrier;
	NSDate *date;
}
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *model;
@property (nonatomic, retain) NSString *os_version;
@property (nonatomic, retain) NSString *carrier;
@property (nonatomic, retain) NSDate *date;

- (NSString *)formattedDate:(NSDate *)aDate;

- (NSDictionary *)apiJSON;
- (NSDictionary *)apiDictionary;
- (ATAPIRequest *)requestForSendingRecord;
/*! Called when we're done using this record. */
- (void)cleanup;
@end
