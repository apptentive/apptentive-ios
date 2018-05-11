//
//  ApptentiveMockDispatchQueue.m
//  ApptentiveTests
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMockDispatchQueue.h"

@interface ApptentiveMockDispatchQueue ()

@property (nonatomic, strong) NSMutableArray * tasks;
@property (nonatomic, assign) BOOL runImmediately;

@end

typedef void (^ApptentiveMockDispatchTask)(void);

@implementation ApptentiveMockDispatchQueue

- (instancetype)init {
	return [self initWithRunImmediately:YES];
}

- (instancetype)initWithRunImmediately:(BOOL)runImmediately {
	self = [super init];
	if (self) {
		_tasks = [NSMutableArray new];
		_runImmediately = runImmediately;
	}
	return self;
}

- (void)dispatchAsync:(void (^)(void))task {
	if (self.runImmediately) {
		task();
	} else {
		[self.tasks addObject:task];
	}
}

- (void)dispatchTasks {
	for (ApptentiveMockDispatchTask task in self.tasks) {
		task();
	}
	[self.tasks removeAllObjects];
}

@end
