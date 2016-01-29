//
//  ATDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceUpdater.h"
#import "ATDeviceInfo.h"
#import "ATConnect_Private.h"
#import "ATWebClient+MessageCenter.h"

@implementation ATDeviceUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATDeviceInfo class];
}

- (id<ATUpdatable>)emptyCurrentVersion {
	return [[ATDeviceInfo alloc] init];
}

- (ATAPIRequest *)requestForUpdating {
	return [[ATConnect sharedConnection].webClient requestForUpdatingDevice:(ATDeviceInfo *)self.currentVersion fromPreviousDevice:(ATDeviceInfo *)self.previousVersion];
}

- (ATDeviceInfo *)currentDevice {
	return (ATDeviceInfo *)self.currentVersion;
}

@end
