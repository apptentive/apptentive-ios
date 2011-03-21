//
//  ATTaskQueue.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATTaskQueue : NSObject <NSCoding> {
@private
    ATTask *activeTask;
    NSMutableArray *tasks;
}
+ (NSString *)taskQueuePath;
+ (BOOL)serializedQueueExists;
+ (ATTaskQueue *)sharedTaskQueue;
+ (void)destroySharedTaskQueue;

- (void)start;
- (void)stop;

@end
