//
//  ATAppConfigurationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATAPIRequest.h"

extern NSString *const ATConfigurationPreferencesChangedNotification;
extern NSString *const ATAppConfigurationLastUpdatePreferenceKey;
extern NSString *const ATAppConfigurationExpirationPreferenceKey;
extern NSString *const ATAppConfigurationMetricsEnabledPreferenceKey;
extern NSString *const ATAppConfigurationMessageCenterEnabledKey;
extern NSString *const ATAppConfigurationHideBrandingKey;

extern NSString *const ATAppConfigurationMessageCenterTitleKey;
extern NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey;
extern NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey;
extern NSString *const ATAppConfigurationMessageCenterEmailRequiredKey;

extern NSString *const ATAppConfigurationAppDisplayNameKey;

@protocol ATAppConfigurationUpdaterDelegate <NSObject>
- (void)configurationUpdaterDidFinish:(BOOL)success;
@end

@interface ATAppConfigurationUpdater : NSObject <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	NSObject<ATAppConfigurationUpdaterDelegate> *delegate;
}
+ (BOOL)shouldCheckForUpdate;
- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end
