//
//  ApptentiveDispatchTask.m
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDispatchTask+Internal.h"
#import "ApptentiveDefines.h"

@interface ApptentiveDispatchTask ()

@property (atomic, assign) BOOL scheduled;
@property (atomic, assign) BOOL cancelled;

@end

@implementation ApptentiveDispatchTask

- (void)executeTask {
	@try {
		self.scheduled = NO;
		
		if (!self.cancelled) {
			[self execute];
		}
	} @catch (NSException *e) {
		ApptentiveLogError(@"Exception while executing task");
	} @finally {
		self.cancelled = NO;
	}
}

- (void)execute {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
}

@end
