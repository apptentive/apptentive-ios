//
//  ApptentiveAsyncLogWriter.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveDispatchQueue;

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveAsyncLogWriter : NSObject

- (instancetype)initWithDestDir:(NSString *)destDir historySize:(NSUInteger)historySize;
- (instancetype)initWithDestDir:(NSString *)destDir historySize:(NSUInteger)historySize queue:(ApptentiveDispatchQueue *)queue;

- (void)logMessage:(NSString *)message;
- (NSString *)createLogFilename;

- (nullable NSArray<NSString *> *)listLogFiles;

@end

NS_ASSUME_NONNULL_END
