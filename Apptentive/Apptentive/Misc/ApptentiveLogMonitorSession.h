//
//  ApptentiveLogMonitorSession.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const ApptentiveLogMonitorSessionDidStart;
extern NSNotificationName const ApptentiveLogMonitorSessionDidStop;

@interface ApptentiveLogMonitorSession : NSObject

/** Email recipients for the log email */
@property (nonatomic, strong) NSArray<NSString *> *emailRecipients;

- (void)start;
- (void)resume;
- (void)stop;

+ (NSString *)manifestFilePath;

@end

@interface ApptentiveLogMonitorSessionIO : NSObject

+ (nullable ApptentiveLogMonitorSession *)readSessionFromPersistentStorage;
+ (void)clearCurrentSession;
+ (void)writeSessionToPersistentStorage:(ApptentiveLogMonitorSession *)session;
+ (nullable ApptentiveLogMonitorSession *)readSessionFromJWT:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
