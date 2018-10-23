//
//  ApptentiveAsyncLogWriter.m
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAsyncLogWriter.h"
#import "ApptentiveDispatchQueue.h"
#import "ApptentiveDefines.h"
#import "ApptentiveLogFileWriteTask.h"
#import "ApptentiveFileUtilities.h"

static const NSUInteger kMessageQueueSize = 256;

@interface ApptentiveAsyncLogWriter ()

@property (nonatomic, strong) NSString *destDir;
@property (nonatomic, strong) NSMutableArray<NSString *> *pendingMessages;
@property (nonatomic, strong) ApptentiveDispatchQueue *writeQueue;
@property (nonatomic, assign) NSUInteger logHistorySize;
@property (nonatomic, strong) ApptentiveDispatchTask *writeQueueTask;

@end

@implementation ApptentiveAsyncLogWriter

- (instancetype)initWithDestDir:(NSString *)destDir historySize:(NSUInteger)historySize {
	return [self initWithDestDir:destDir historySize:historySize queue:[ApptentiveDispatchQueue createQueueWithName:@"Log Queue" concurrencyType:ApptentiveDispatchQueueConcurrencyTypeSerial qualityOfService:NSQualityOfServiceBackground]];
}
- (instancetype)initWithDestDir:(NSString *)destDir historySize:(NSUInteger)historySize queue:(ApptentiveDispatchQueue *)queue {
	APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(destDir)
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(queue)
	self = [super init];
	if (self) {
		_destDir = destDir;
		_logHistorySize = historySize;
		_writeQueue = queue;
		_pendingMessages = [NSMutableArray arrayWithCapacity:kMessageQueueSize];
		
		NSString *logFile = [destDir stringByAppendingPathComponent:[self createLogFilename]];
		ApptentiveLogVerbose(ApptentiveLogTagUtility, @"Log file: %@", logFile);
		
		_writeQueueTask = [[ApptentiveLogFileWriteTask alloc] initWithFile:logFile buffer:_pendingMessages];
		
		// run initialization as the first task on the write queue
		[_writeQueue dispatchAsync:^{
			[self prepareLogsDirectory:destDir];
		}];
	}
	return self;
}

- (void)prepareLogsDirectory:(NSString *)logsDir {
	if (![ApptentiveFileUtilities directoryExistsAtPath:logsDir]) {
		return;
	}
	
	// list existing log files
	NSError *error;
	NSArray<NSString *> *files = [ApptentiveFileUtilities listFilesAtPath:logsDir error:&error];
	if (files == nil) {
		ApptentiveLogError(ApptentiveLogTagUtility, @"Error getting contents of directory %@ (%@).", logsDir, error);
		return;
	}
	
	// anything to clear?
	if (files.count <= self.logHistorySize) {
		return;
	}
	
	// sort existing log files by modification date (oldest come first)
	files = [files sortedArrayUsingSelector:@selector(compare:)];
	
	// don't delete latest files which fit into the history size
	NSArray *filesToDelete = [files subarrayWithRange:NSMakeRange(0, files.count - self.logHistorySize)];
	
	// delete oldest files if the total count exceed the log history size
	for (NSString *file in filesToDelete) {
		if (![ApptentiveFileUtilities deleteFileAtPath:file error:&error]) {
			ApptentiveLogError(ApptentiveLogTagUtility, @"Error while deleteing file %@ (%@).", file, error);
		}
	}
}

- (NSArray<NSString *> *)listLogFiles {
	return [ApptentiveFileUtilities listFilesAtPath:self.destDir error:NULL];
}

#pragma mark -
#pragma mark Messages

- (void)logMessage:(NSString *)message {
	ApptentiveAssertNotNil(message, @"Attempted to add a nil message");
	if (message != nil) {
		@synchronized (self.pendingMessages) {
			[self.pendingMessages addObject:message];
			[_writeQueue dispatchTaskOnce:_writeQueueTask];
		}
	}
}

#pragma mark -
#pragma Unit tests

- (NSString *)createLogFilename {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
	[formatter setDateFormat:@"yyyy-MM-dd_hh-mm-ss"];
	return [NSString stringWithFormat:@"apptentive-%@.log", [formatter stringFromDate:[NSDate date]]];
}

@end
