//
//  ATPersonInfo.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATCustomDataContainer.h"

@interface ATPersonInfo : ATCustomDataContainer

@property (readonly, nonatomic) NSString *apptentiveID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;

/** If json is nil will not create a new person and will return nil. */
+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json;

- (NSDictionary *)apiJSON;

@end
