//
//  ApptentiveStopWatch.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/11/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveStopWatch : NSObject

@property (nonatomic, readonly) NSTimeInterval elapsedSeconds;
@property (nonatomic, readonly) NSTimeInterval elapsedMilliseconds;

+ (instancetype)stopWatch;
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
