//
//  ATDeviceUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATDiffingUpdater.h"

@class ATDeviceInfo;

@interface ATDeviceUpdater : ATDiffingUpdater

@property (readonly, nonatomic) ATDeviceInfo *currentDevice;

@end
