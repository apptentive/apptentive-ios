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

/** Email recipients for the log email */
@property (nonatomic, strong) NSArray<NSString *> *emailRecipients;

/** New log level */
@property (nonatomic, assign) ApptentiveLogLevel logLevel;

/** True if configuration was restored from the persistent storage */
@property (nonatomic, readonly, getter=isRestored) BOOL restored;

@end


@interface ApptentiveLogMonitor : NSObject

+ (BOOL)tryInitializeWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature;

+ (instancetype)sharedInstance;

- (void)resume;

@end

NS_ASSUME_NONNULL_END
