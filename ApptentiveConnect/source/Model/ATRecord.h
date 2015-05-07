//
//  ATRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATJSONModel.h"

@interface ATRecord : NSManagedObject <ATJSONModel>

@property (nonatomic, strong) NSString *apptentiveID;
@property (nonatomic, strong) NSNumber *creationTime;
@property (nonatomic, strong) NSNumber *clientCreationTime;
@property (nonatomic, strong) NSString *clientCreationTimezone;
@property (nonatomic, strong) NSNumber *clientCreationUTCOffset;

+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp;

- (void)setup;
- (void)updateClientCreationTime;
- (BOOL)isClientCreationTimeEmpty;
- (BOOL)isCreationTimeEmpty;
@end
