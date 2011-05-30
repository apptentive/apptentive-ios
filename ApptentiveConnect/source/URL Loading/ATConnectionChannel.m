//
//  ATConnectionChannel.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ATConnectionChannel.h"
#import "ATURLConnection.h"
#import "ATURLConnection_Private.h"

@implementation ATConnectionChannel
@synthesize maximumConnections;

- (id)init {
	if ((self = [super init])) {
		maximumConnections = 2;
		active = [[NSMutableSet alloc] init];
		waiting = [[NSMutableArray alloc] init];
		return self;
	}
	return nil;
}

- (void)update {
	while ([active count] < maximumConnections && [waiting count] > 0) {
		ATURLConnection *loader = [[waiting objectAtIndex:0] retain];
		[active addObject:loader];
		[loader addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
		[waiting removeObjectAtIndex:0];
		[loader start];
		[loader release];
	}
}

- (void)addConnection:(ATURLConnection *)connection {
    @synchronized(self) {
        [waiting addObject:connection];
        [self update];
    }
}

- (void)cancelAllConnections {
    @synchronized (self) {
        for (ATURLConnection *loader in active) {
            [loader removeObserver:self forKeyPath:@"isFinished"];
            [loader cancel];
        }
        [active removeAllObjects];
        for (ATURLConnection *loader in waiting) {
            [loader cancel];
        }
        [waiting removeAllObjects];
    }
}

- (void)cancelConnection:(ATURLConnection *)connection {
	if ([active containsObject:connection]) {
		[connection cancel];
		[active removeObject:connection];
	}
	
	if ([waiting containsObject:connection]) {
		[connection cancel];
		[waiting removeObject:connection];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"isFinished"] && [(ATURLConnection *)object isFinished]) {
		[object removeObserver:self forKeyPath:@"isFinished"];
		[active removeObject:object];
		[self update];
	}
}

- (void)dealloc {
	[self cancelAllConnections];
	[active release];
	[waiting release];
	[super dealloc];
}
@end
