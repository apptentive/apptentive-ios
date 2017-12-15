//
//  ApptentiveLogWriter.h
//  ApptentiveLogWriter
//
//  Created by Alex Lementuev on 10/12/17.
//  Copyright 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogWriter.h"


@interface ApptentiveLogWriter ()

@property (nonatomic, readonly) dispatch_queue_t writerQueue;
@property (nonatomic, assign) BOOL running;

@end


@implementation ApptentiveLogWriter

- (instancetype)initWithPath:(NSString *)path {
	self = [super init];
	if (self) {
		_path = path;
	}
	return self;
}

- (void)start {
	self.running = YES;
	_writerQueue = dispatch_queue_create("Apptentive Log Writer", DISPATCH_QUEUE_SERIAL);
}

- (void)stop {
	dispatch_async(_writerQueue, ^{
	  self.running = NO;
	  if (self.finishCallback) {
		  self.finishCallback(self);
	  }
	});
}

- (void)appendMessage:(NSString *)message {
	NSDate *timeStamp = [NSDate new];
	dispatch_async(_writerQueue, ^{
	  if (self.running) {
		  [self writeMessage:[[NSString alloc] initWithFormat:@"%@ %@\n", timeStamp, message]];
	  }
	});
}

- (void)writeMessage:(NSString *)message {
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_path];
	if (fileHandle == nil) {
		[[NSFileManager defaultManager] createFileAtPath:_path contents:nil attributes:nil];
		fileHandle = [NSFileHandle fileHandleForWritingAtPath:_path];
	}
	[fileHandle seekToEndOfFile];
	[fileHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
	[fileHandle closeFile];
}

@end
