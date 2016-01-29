//
//  ATDiffingUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATUpdater.h"

@interface ATDiffingUpdater : ATUpdater

#pragma mark - For subclass use only

@property (readonly, nonatomic) id<ATUpdatable> previousVersion;
@property (strong, nonatomic) id<ATUpdatable> updateVersion;
@property (readonly, nonatomic) id<ATUpdatable> currentVersion;

- (id<ATUpdatable>)previousVersionFromUserDefaults:(NSUserDefaults *)userDefaults;
- (void)removePreviousVersionFromUserDefaults:(NSUserDefaults *)userDefaults;

@end
