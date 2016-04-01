//
//  ApptentiveionManager.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ATConnectionManager.h"
#import "ATConnectionChannel.h"

static ApptentiveionManager *sharedSingleton = nil;

#define PLACEHOLDER_CHANNEL_NAME @"ATDefaultChannel"


@interface ApptentiveionManager ()
- (ApptentiveionChannel *)channelForName:(NSString *)channelName;
@end


@implementation ApptentiveionManager {
	NSMutableDictionary *channels;
}

+ (ApptentiveionManager *)sharedSingleton {
	@synchronized(self) {
		if (!sharedSingleton) {
			sharedSingleton = [[ApptentiveionManager alloc] init];
		}
	}
	return sharedSingleton;
}

- (id)init {
	if ((self = [super init])) {
		channels = [[NSMutableDictionary alloc] init];
		return self;
	}
	return nil;
}

- (void)start {
	for (ApptentiveionChannel *channel in [channels allValues]) {
		[channel update];
	}
}

- (void)stop {
	for (ApptentiveionChannel *channel in [channels allValues]) {
		[channel cancelAllConnections];
	}
}

- (void)addConnection:(ATURLConnection *)connection toChannel:(NSString *)channelName {
	ApptentiveionChannel *channel = [self channelForName:channelName];
	[channel addConnection:connection];
}

- (void)cancelAllConnectionsInChannel:(NSString *)channelName {
	ApptentiveionChannel *channel = [self channelForName:channelName];
	[channel cancelAllConnections];
}

- (void)cancelConnection:(ATURLConnection *)connection inChannel:(NSString *)channelName {
	ApptentiveionChannel *channel = [self channelForName:channelName];
	[channel cancelConnection:connection];
}

- (void)setMaximumActiveConnections:(NSInteger)maximumConnections forChannel:(NSString *)channelName {
	ApptentiveionChannel *channel = [self channelForName:channelName];
	channel.maximumConnections = maximumConnections;
}


- (ApptentiveionChannel *)channelForName:(NSString *)channelName {
	if (!channelName) {
		channelName = PLACEHOLDER_CHANNEL_NAME;
	}
	ApptentiveionChannel *channel = [channels objectForKey:channelName];
	if (!channel) {
		channel = [[ApptentiveionChannel alloc] init];
		[channels setObject:channel forKey:channelName];
	}
	return channel;
}

- (void)dealloc {
	[self stop];
	[channels removeAllObjects];
}
@end
