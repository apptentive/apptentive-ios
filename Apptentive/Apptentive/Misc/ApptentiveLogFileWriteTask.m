//
//  ApptentiveLogFileWriteTask.m
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogFileWriteTask.h"
#import "ApptentiveDefines.h"
#import "ApptentiveFileUtilities.h"

@interface ApptentiveLogFileWriteTask ()

@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSMutableArray<NSString *> *buffer;
@property (nonatomic, strong) NSMutableArray<NSString *> *queuedMessagesTemp;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation ApptentiveLogFileWriteTask

- (instancetype)initWithFile:(NSString *)file buffer:(NSMutableArray<NSString *> *)buffer {
	APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(file)
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(buffer)
	self = [super init];
	if (self) {
		_file = file;
		_fileHandle = [[self class] openFileWrite:file];
		if (_fileHandle == nil) {
			ApptentiveLogCrit(ApptentiveLogTagUtility, @"Unable to start log writing task");
			return nil;
		}
		
		_buffer = buffer;
		_queuedMessagesTemp = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc {
	[self.fileHandle synchronizeFile];
	[self.fileHandle closeFile];
}

- (void)execute {
	// we don't want to acquire the mutex for too long so just copy pending messages
	// to the temp list which would be used in a blocking IO
	@synchronized (_buffer) {
		[_queuedMessagesTemp addObjectsFromArray:_buffer];
		[_buffer removeAllObjects];
	}
	
	// write to a file
	@autoreleasepool {
		NSMutableString *text = [NSMutableString new];
		for (NSString *line in _queuedMessagesTemp) {
			[text appendString:line];
			[text appendString:@"\n"];
		}
		NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
		[self.fileHandle writeData:data];
		[self.fileHandle synchronizeFile];
	}
	
	[_queuedMessagesTemp removeAllObjects];
}

#pragma mark -
#pragma mark File Handler

+ (NSFileHandle *)openFileWrite:(NSString *)path {
	// create output directory if it doesn't exist
	NSString *dirName = [path stringByDeletingLastPathComponent];
	NSError *error;
	BOOL directoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:&error];
	if (!directoryCreated) {
		ApptentiveLogCrit(ApptentiveLogTagUtility, @"Unable to create log output directory '%@' (%@)", dirName, error);
		return nil;
	}
	
	// delete an old file if any
	BOOL oldFileDeleted = [ApptentiveFileUtilities deleteFileAtPath:path];
	ApptentiveAssertFalse(oldFileDeleted, @"Duplicate log file existed: %@", path);
	
	// create a new log file
	BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
	if (!fileCreated) {
		ApptentiveLogCrit(ApptentiveLogTagUtility, @"Unable to create log file '%@'", path);
		return nil;
	}
	
	// open a file handle for writing
	return [NSFileHandle fileHandleForWritingAtPath:path];
}

@end
