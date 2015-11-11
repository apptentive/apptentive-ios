//
//  ATFileAttachment.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATFileAttachment.h"
#import "ATBackend.h"
#import "ATMessage.h"
#import "ATUtilities.h"
#import "ATData.h"
#import "NSDictionary+ATAdditions.h"

@interface ATFileAttachment ()
- (NSString *)fullLocalPathForFilename:(NSString *)filename;
- (NSString *)filenameForThumbnailOfSize:(CGSize)size;
- (void)deleteSidecarIfNecessary;
@end

@implementation ATFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic message;
@dynamic remoteURL;
@dynamic remoteThumbnailURL;

+ (instancetype)newInstanceWithFileData:(NSData *)fileData MIMEType:(NSString *)MIMEType {
	ATFileAttachment *attachment = (ATFileAttachment *)[ATData newEntityNamed:NSStringFromClass(self)];
	attachment.mimeType = MIMEType;
	[attachment setFileData:fileData];
	return attachment;
}

+ (instancetype)newInstanceWithJSON:(NSDictionary *)JSON {
	ATFileAttachment *attachment = (ATFileAttachment *)[ATData newEntityNamed:NSStringFromClass(self)];
	[attachment updateWithJSON:JSON];

	return attachment;
}

- (void)updateWithJSON:(NSDictionary *)JSON {
	NSString *remoteURLString = [JSON at_safeObjectForKey:@"url"];
	if (remoteURLString && [remoteURLString isKindOfClass:[NSString class]] && [NSURL URLWithString:remoteURLString]) {
		[self willChangeValueForKey:@"remoteURL"];
		[self setPrimitiveValue:remoteURLString forKey:@"remoteURL"];
		[self didChangeValueForKey:@"remoteURL"];
	}

	NSString *remoteThumbnailURL = [JSON at_safeObjectForKey:@"thumbnail_url"];
	if (remoteThumbnailURL && [remoteThumbnailURL isKindOfClass:[NSString class]] && [NSURL URLWithString:remoteThumbnailURL]) {
		[self willChangeValueForKey:@"remoteThumbnailURL"];
		[self setPrimitiveValue:remoteThumbnailURL forKey:@"remoteThumbnailURL"];
		[self didChangeValueForKey:@"remoteThumbnailURL"];
	}

	NSString *MIMEType = [JSON at_safeObjectForKey:@"content_type"];
	if (MIMEType && [MIMEType isKindOfClass:[NSString class]]) {
		[self setValue:MIMEType forKey:@"mimeType"];
	}
}

- (void)prepareForDeletion {
	[self setFileData:nil];
}

- (void)setFileData:(NSData *)data {
	[self deleteSidecarIfNecessary];
	self.localPath = nil;
	if (data) {
		self.localPath = [ATUtilities randomStringOfLength:20];
		if (![data writeToFile:[self fullLocalPath] atomically:YES]) {
			ATLogError(@"Unable to save file data to path: %@", [self fullLocalPath]);
			self.localPath = nil;
		}
		self.mimeType = @"application/octet-stream";
		self.name = [NSString stringWithString:self.localPath];
	}
}

- (NSData *)fileData {
	NSString *path = [self fullLocalPath];
	NSData *fileData = nil;
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSError *error = nil;
		fileData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
		if (!fileData) {
			ATLogError(@"Unable to get contents of file path for uploading: %@", error);
		} else {
			return fileData;
		}
	}

	ATLogError(@"Missing sidecar file for %@", self);
	return nil;
}

- (NSURL *)remoteURL {
	NSString *remoteURLString = [self primitiveValueForKey:@"remoteURL"];

	if (remoteURLString) {
		return [NSURL URLWithString:remoteURLString];
	} else {
		return nil;
	}
}

- (NSURL *)remoteThumbnailURL {
	NSString *remoteThumbnailURLString = [self primitiveValueForKey:@"remoteThumbnailURL"];

	if (remoteThumbnailURLString) {
		return [NSURL URLWithString:remoteThumbnailURLString];
	} else {
		return nil;
	}
}

- (NSURL *)beginMoveToStorageFrom:(NSURL *)temporaryLocation {
	if (temporaryLocation && temporaryLocation.isFileURL) {
		NSURL *newLocation = [NSURL fileURLWithPath:[self fullLocalPathForFilename:[ATUtilities randomStringOfLength:20]]];
		NSError *error = nil;
		if ([[NSFileManager defaultManager] moveItemAtURL:temporaryLocation toURL:newLocation error:&error]) {
			return newLocation;
		} else {
			ATLogError(@"Unable to write attachment to URL: %@, %@", newLocation, error);
			return nil;
		}
	} else {
		ATLogError(@"Temporary file location (%@) is nil or not file URL", temporaryLocation);
		return nil;
	}
}

- (void)completeMoveToStorageFor:(NSURL *)storageLocation {
	[self deleteSidecarIfNecessary];
	self.localPath = storageLocation.lastPathComponent;
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

- (NSString *)filenameForThumbnailOfSize:(CGSize)size {
	if (self.localPath == nil) {
		return nil;
	}
	return [NSString stringWithFormat:@"%@_%dx%d_fit.thumbnail", self.localPath, (int)floor(size.width), (int)floor(size.height)];
}

- (void)deleteSidecarIfNecessary {
	if (self.localPath) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *fullPath = [self fullLocalPath];
		NSError *error = nil;
		BOOL isDir = NO;
		if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || isDir) {
			ATLogError(@"File attachment sidecar doesn't exist at path or is directory: %@, %d", fullPath, isDir);
			return;
		}
		if (![fm removeItemAtPath:fullPath error:&error]) {
			ATLogError(@"Error removing attachment at path: %@. %@", fullPath, error);
			return;
		}
		// Delete any thumbnails.
		NSArray *filenames = [fm contentsOfDirectoryAtPath:[[ATBackend sharedBackend] attachmentDirectoryPath] error:&error];
		if (!filenames) {
			ATLogError(@"Error listing attachments directory: %@", error);
		} else {
			for (NSString *filename in filenames) {
				if ([filename rangeOfString:self.localPath].location == 0) {
					NSString *thumbnailPath = [self fullLocalPathForFilename:filename];
					
					if (![fm removeItemAtPath:thumbnailPath error:&error]) {
						ATLogError(@"Error removing attachment thumbnail at path: %@. %@", thumbnailPath, error);
						continue;
					}
				}
			}
		}
		self.localPath = nil;
	}
}

- (UIImage *)thumbnailOfSize:(CGSize)size {
	NSString *filename = [self filenameForThumbnailOfSize:size];
	if (!filename) {
		return nil;
	}
	NSString *path = [self fullLocalPathForFilename:filename];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	if (image == nil) {
		image = [self createThumbnailOfSize:size];
	}
	return image;
}

- (UIImage *)createThumbnailOfSize:(CGSize)size {
	CGFloat scale = [[UIScreen mainScreen] scale];
	NSString *fullLocalPath = [self fullLocalPath];
	NSString *filename = [self filenameForThumbnailOfSize:size];
	NSString *fullThumbnailPath = [self fullLocalPathForFilename:filename];

	UIImage *image = [UIImage imageWithContentsOfFile:fullLocalPath];
	UIImage *thumb = [ATUtilities imageByScalingImage:image toFitSize:size scale:scale];
	[UIImagePNGRepresentation(thumb) writeToFile:fullThumbnailPath atomically:YES];
	return thumb;
}

//TODO: Should this be removed?
- (void)createThumbnailOfSize:(CGSize)size completion:(void (^)(void))completion {
	CGFloat scale = [[UIScreen mainScreen] scale];
	NSString *fullLocalPath = [self fullLocalPath];
	NSString *filename = [self filenameForThumbnailOfSize:size];
	NSString *fullThumbnailPath = [self fullLocalPathForFilename:filename];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		UIImage *image = [UIImage imageWithContentsOfFile:fullLocalPath];
		UIImage *thumb = [ATUtilities imageByScalingImage:image toSize:size scale:scale fromITouchCamera:NO];
		[UIImagePNGRepresentation(thumb) writeToFile:fullThumbnailPath atomically:YES];
		dispatch_sync(dispatch_get_main_queue(), ^{
			if (completion) {
				completion();
			}
		});
	});
}
@end
