//
//  ATExpiringUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATUpdater.h"

@class ATExpiry;

@interface ATExpiringUpdater : ATUpdater

#pragma for subclass use only

- (ATExpiry *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults;
@property (strong, nonatomic) ATExpiry *expiry;
- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults;
- (ATExpiry *)emptyExpiry;

@end
