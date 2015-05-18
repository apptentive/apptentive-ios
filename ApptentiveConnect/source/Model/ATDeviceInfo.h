//
//  ATDeviceInfo.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATDeviceInfo : NSObject
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

+ (NSString *)carrier;

- (NSDictionary *)apiJSONComparedWith:(NSDictionary *)lastVersion;
@end



