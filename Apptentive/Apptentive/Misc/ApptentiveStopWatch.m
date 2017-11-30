//
//  ApptentiveStopWatch.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/11/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveStopWatch.h"


NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveStopWatch ()

@property (nonatomic, strong) NSDate *startDate;

@end


@implementation ApptentiveStopWatch

+ (instancetype)stopWatch {
	return [[self alloc] init];
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_startDate = [[NSDate alloc] init];
	}
	return self;
}

- (NSTimeInterval)elapsedSeconds {
	return -[self.startDate timeIntervalSinceNow];
}

- (NSTimeInterval)elapsedMilliseconds {
	return [self elapsedSeconds] * 1000;
}

@end

NS_ASSUME_NONNULL_END
