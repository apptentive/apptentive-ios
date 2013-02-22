//
//  ATFileAttachment.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATFileAttachment.h"
#import "ATBackend.h"
#import "ATFileMessage.h"
#import "ATUtilities.h"

@interface ATFileAttachment ()
- (NSString *)fullLocalPathForFilename:(NSString *)filename;
- (void)deleteSidecarIfNecessary;
@end

@implementation ATFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic transient;
@dynamic userVisible;
@dynamic fileMessage;

- (void)setFileData:(NSData *)data {
	[self deleteSidecarIfNecessary];
	self.localPath = nil;
	if (data) {
		self.localPath = [ATUtilities randomStringOfLength:20];
		if (![data writeToFile:[self fullLocalPath] atomically:YES]) {
			NSLog(@"Unable to save file data to path: %@", [self fullLocalPath]);
			self.localPath = nil;
		}
		self.mimeType = @"application/octet-stream";
		self.name = [NSString stringWithString:self.localPath];
	}
}

- (void)setFileFromSourcePath:(NSString *)sourceFilename {
	[self deleteSidecarIfNecessary];
	self.localPath = nil;
	if (sourceFilename) {
		BOOL isDir = NO;
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:sourceFilename isDirectory:&isDir] || isDir) {
			NSLog(@"Either source attachment file doesn't exist or is directory: %@, %d", sourceFilename, isDir);
			return;
		}
		self.localPath = [ATUtilities randomStringOfLength:20];
		NSError *error = nil;
		if (![fm copyItemAtPath:sourceFilename toPath:[self fullLocalPath] error:&error]) {
			self.localPath = nil;
			NSLog(@"Unable to write attachment to path: %@, %@", [self fullLocalPath], error);
			return;
		}
		self.mimeType = @"application/octet-stream";
		self.name = [sourceFilename lastPathComponent];
	}
}

- (NSString *)fullLocalPath {
	return [self fullLocalPathForFilename:self.localPath];
}

- (NSString *)fullLocalPathForFilename:(NSString *)filename {
	if (!filename) {
		return nil;
	}
	return [[[ATBackend sharedBackend] attachmentDirectoryPath] stringByAppendingPathComponent:filename];
}

- (void)deleteSidecarIfNecessary {
	if (self.localPath) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *fullPath = [self fullLocalPath];
		NSError *error = nil;
		BOOL isDir = NO;
		if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || isDir) {
			NSLog(@"File attachment sidecar doesn't exist at path or is directory: %@, %d", fullPath, isDir);
			return;
		}
		if (![fm removeItemAtPath:fullPath error:&error]) {
			NSLog(@"Error removing attachment at path: %@. %@", fullPath, error);
			return;
		}
		self.localPath = nil;
	}
}
@end
