//
//  ApptentiveAppRelease.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentiveVersion;

@interface ApptentiveAppRelease : ApptentiveState

@property (readonly, strong, nonatomic) NSString *type;
@property (readonly, strong, nonatomic) ApptentiveVersion *version;
@property (readonly, strong, nonatomic) ApptentiveVersion *build;
@property (readonly, assign, nonatomic) BOOL hasAppStoreReceipt;
@property (readonly, assign, nonatomic, getter=isDebugBuild) BOOL debugBuild;
@property (readonly, assign, nonatomic, getter=isOverridingStyles) BOOL overridingStyles;
@property (readonly, assign, nonatomic, getter=isUpdateVersion) BOOL updateVersion;
@property (readonly, assign, nonatomic, getter=isUpdateBuild) BOOL updateBuild;

@property (readonly, strong, nonatomic) NSDate *timeAtInstallTotal;
@property (readonly, strong, nonatomic) NSDate *timeAtInstallVersion;
@property (readonly, strong, nonatomic) NSDate *timeAtInstallBuild;

- (instancetype)initWithCurrentAppRelease;

- (void)resetBuild;
- (void)resetVersion;

@end
