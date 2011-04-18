//
//  ATTaskQueue.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATTask;

@interface ATTaskQueue : NSObject <NSCoding> {
@private
    ATTask *activeTask;
    NSMutableArray *tasks;
}
+ (NSString *)taskQueuePath;
+ (BOOL)serializedQueueExists;
+ (ATTaskQueue *)sharedTaskQueue;
+ (void)releaseSharedTaskQueue;

- (void)addTask:(ATTask *)task;
- (NSUInteger)count;
- (void)start;
- (void)stop;

@end
