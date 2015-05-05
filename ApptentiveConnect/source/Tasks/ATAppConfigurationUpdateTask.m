//
//  ATAppConfigurationUpdateTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdateTask.h"
#import "ATBackend.h"

@implementation ATAppConfigurationUpdateTask {
	ATAppConfigurationUpdater *configurationUpdater;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	if (configurationUpdater == nil && [ATAppConfigurationUpdater shouldCheckForUpdate]) {
		configurationUpdater = [[ATAppConfigurationUpdater alloc] initWithDelegate:self];
		self.inProgress = YES;
		[configurationUpdater update];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (configurationUpdater) {
		[configurationUpdater cancel];
		configurationUpdater = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (configurationUpdater) {
		return [configurationUpdater percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"configuration update";
}

#pragma mark ATAppConfigurationUpdaterDelegate
- (void)configurationUpdaterDidFinish:(BOOL)success {
	@synchronized(self) {
		if (configurationUpdater) {
			if (!success) {
				self.failed = YES;
				[self stop];
			} else {
				self.finished = YES;
			}
		}
	}
}
@end
