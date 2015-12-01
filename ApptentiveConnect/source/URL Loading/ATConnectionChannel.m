//
//  ATConnectionChannel.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ATConnectionChannel.h"
#import "ATURLConnection.h"
#import "ATURLConnection_Private.h"


@interface ATConnectionChannel ()

@property (strong, nonatomic) NSMutableSet *active;
@property (strong, nonatomic) NSMutableArray *waiting;

@end


@implementation ATConnectionChannel

- (id)init {
	if ((self = [super init])) {
		_maximumConnections = 2;
		_active = [[NSMutableSet alloc] init];
		_waiting = [[NSMutableArray alloc] init];
		return self;
	}
	return nil;
}

- (void)update {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
		return;
	}

	@synchronized(self) {
		@autoreleasepool {
			while ([self.active count]<self.maximumConnections && [self.waiting count]> 0) {
				ATURLConnection *loader = [self.waiting objectAtIndex:0];
				[self.active addObject:loader];
				[loader addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
				[self.waiting removeObjectAtIndex:0];
				[loader start];
			}
		}
	}
}

- (void)addConnection:(ATURLConnection *)connection {
	@synchronized(self) {
		[self.waiting addObject:connection];
		[self update];
	}
}

- (void)cancelAllConnections {
	@synchronized(self) {
		for (ATURLConnection *loader in self.active) {
			[loader removeObserver:self forKeyPath:@"isFinished"];
			[loader cancel];
		}
		[self.active removeAllObjects];
		for (ATURLConnection *loader in self.waiting) {
			[loader cancel];
		}
		[self.waiting removeAllObjects];
	}
}

- (void)cancelConnection:(ATURLConnection *)connection {
	@synchronized(self) {
		if ([self.active containsObject:connection]) {
			[connection removeObserver:self forKeyPath:@"isFinished"];
			[connection cancel];
			[self.active removeObject:connection];
		}

		if ([self.waiting containsObject:connection]) {
			[connection cancel];
			[self.waiting removeObject:connection];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"isFinished"] && [(ATURLConnection *)object isFinished]) {
		@synchronized(self) {
			[object removeObserver:self forKeyPath:@"isFinished"];
			[self.active removeObject:object];
		}
		[self update];
	}
}

- (void)dealloc {
	[self cancelAllConnections];
}
@end
