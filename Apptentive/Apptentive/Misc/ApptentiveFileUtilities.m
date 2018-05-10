//
//  ApptentiveFileUtilities.m
//  Apptentive
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveFileUtilities.h"
#import "ApptentiveUtilities.h"

@implementation ApptentiveFileUtilities

+ (BOOL)fileExistsAtPath:(NSString *)path {
	return path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)directoryExistsAtPath:(NSString *)path {
	BOOL directory;
	return path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory] && directory;
}

+ (BOOL)deleteFileAtPath:(NSString *)path {
	return [self deleteFileAtPath:path error:NULL];
}

+ (BOOL)deleteFileAtPath:(NSString *)path error:(NSError **)error {
	return path != nil && [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (BOOL)deleteDirectoryAtPath:(NSString *)path error:(NSError **)error {
	return path != nil && [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (nullable NSArray<NSString *> *)listFilesAtPath:(NSString *)path error:(NSError **)error {
	if (path.length == 0) {
		if (error) {
			*error = [ApptentiveUtilities errorWithCode:100 failureReason:@"Path is nil or empty"];
		}
		return nil;
	}
	
	NSArray<NSString *> *names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:error];
	if (names == nil) {
		return nil;
	}
	
	NSMutableArray<NSString *> *files = [NSMutableArray arrayWithCapacity:names.count];
	for (NSString *name in names) {
		[files addObject:[path stringByAppendingPathComponent:name]];
	}
	return files;
}

@end
