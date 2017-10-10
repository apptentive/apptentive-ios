//
//  ApptentiveLogMonitor.h
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveLogMonitorConfigration : NSObject

/** Access token for session verification */
@property (nonatomic, readonly) NSString *accessToken;

/** Email recipients for the log email */
@property (nonatomic, strong) NSArray<NSString *> *emailRecipients;

/** New log level */
@property (nonatomic, assign) ApptentiveLogLevel logLevel;

/** True if configuration was restored from the persistent storage */
@property (nonatomic, readonly, getter=isRestored) BOOL restored;

/** Create a new configuration with an access token and default parameters */
- (instancetype)initWithAccessToken:(NSString *)accessToken;

@end

@interface ApptentiveLogMonitor : NSObject

+ (BOOL)tryInitializeWithConfiguration:(ApptentiveLogMonitorConfigration *)configuration;

@end

NS_ASSUME_NONNULL_END
