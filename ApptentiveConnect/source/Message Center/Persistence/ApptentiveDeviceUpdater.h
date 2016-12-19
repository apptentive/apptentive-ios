//
//  ApptentiveDeviceUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ATDeviceLastUpdatePreferenceKey;
extern NSString *const ATDeviceLastUpdateValuePreferenceKey;

@protocol ATDeviceUpdaterDelegate;


@interface ApptentiveDeviceUpdater : NSObject
+ (BOOL)shouldUpdate;
+ (NSDictionary *)lastSavedVersion;
+ (void)resetDeviceInfo;

- (void)update;
@end
