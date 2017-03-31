
//
//  ApptentiveAttachment.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAttachment.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>

// TODO: see if we can remove/inject these dependencies
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"

@implementation ApptentiveAttachment

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			return nil;
		}

		_name = JSON[@"original_name"];
		_contentType = JSON[@"content_type"];

		NSNumber *sizeNumber = JSON[@"size"];
		if ([sizeNumber isKindOfClass:[NSNumber class]]) {
			_size = [sizeNumber integerValue];
		}

		NSString *URLString = JSON[@"url"];
		if ([URLString isKindOfClass:[NSString class]]) {
			_remoteURL = [NSURL URLWithString:URLString];
		}
	}

	return self;
}

- (instancetype)initWithPath:(NSString *)path contentType:(NSString *)contentType name:(NSString *)name {
	self = [super init];

	if (self) {
		BOOL isDirectory;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
			return nil;
		}

		_fileName = path;
		_contentType = contentType;
		_name = name;
	}

	return self;
}

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType name:(NSString *)name {
	self = [super init];

	if (self) {
		// TODO: create file from data

		_contentType = contentType;
		_name = name;
	}

	return self;
}

- (NSURL *)permanentLocation {
	NSString *name = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:self.extension];
	return [NSURL fileURLWithPath:[[self class] fullLocalPathForFilename:name]];
}

- (void)completeMoveToStorageFor:(NSURL *)storageLocation {
	[self deleteSidecarIfNecessary];
	_fileName = storageLocation.lastPathComponent;
}

- (NSString *)fullLocalPath {
	return [[self class] fullLocalPathForFilename:self.fileName];
}

#pragma mark - Computed Properties

- (NSString *)extension {
	NSString *_extension = nil;

	if (self.contentType) {
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(self.contentType), NULL);
		CFStringRef cf_extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
		CFRelease(uti);
		if (cf_extension) {
			_extension = [(__bridge NSString *)cf_extension copy];
			CFRelease(cf_extension);
		}
	}

	if (_extension.length == 0 && self.name) {
		_extension = self.name.pathExtension;
	}

	if (_extension.length == 0 && self.remoteURL) {
		_extension = self.remoteURL.pathExtension;
	}

	if (_extension.length == 0) {
		_extension = @"file";
	}

	return _extension;
}

- (BOOL)canCreateThumbnail {
	return [[self class] canCreateThumbnailForMIMEType:self.contentType];
}

- (UIImage *)thumbnailOfSize:(CGSize)size {
	NSString *filename = [self filenameForThumbnailOfSize:size];
	if (!filename) {
		return nil;
	}
	NSString *path = [[self class] fullLocalPathForFilename:filename];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	if (image == nil) {
		image = [self createThumbnailOfSize:size];
	}
	return image;
}

#pragma mark - Private

- (NSString *)filenameForThumbnailOfSize:(CGSize)size {
	if (self.fileName == nil) {
		return nil;
	}
	return [NSString stringWithFormat:@"%@_%dx%d_fit.jpeg", self.fileName, (int)floor(size.width), (int)floor(size.height)];
}

- (UIImage *)createThumbnailOfSize:(CGSize)size {
	CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.fullLocalPath], NULL);
	CFDictionaryRef options = (__bridge CFDictionaryRef) @{
														   (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
														   (id)
														   kCGImageSourceCreateThumbnailFromImageAlways: @YES,
														   (id)
														   kCGImageSourceThumbnailMaxPixelSize: @(fmax(size.width, size.height))
														   };
	CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
	CFRelease(src);

	UIImage *thumbnailImage = nil;

	if (thumbnail) {
		thumbnailImage = [UIImage imageWithCGImage:thumbnail];
		CGImageRelease(thumbnail);

		NSString *filename = [self filenameForThumbnailOfSize:size];
		NSString *fullThumbnailPath = [[self class] fullLocalPathForFilename:filename];
		[UIImagePNGRepresentation(thumbnailImage) writeToFile:fullThumbnailPath atomically:YES];
	}

	return thumbnailImage;
}

+ (NSString *)fullLocalPathForFilename:(NSString *)filename {
	if (!filename) {
		return nil;
	}
	return [[Apptentive.shared.backend attachmentDirectoryPath] stringByAppendingPathComponent:filename];
}

+ (BOOL)canCreateThumbnailForMIMEType:(NSString *)MIMEType {
	static NSSet *thumbnailableMIMETypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		CFArrayRef thumbnailableUTIs = CGImageSourceCopyTypeIdentifiers();

		NSMutableSet *mimeTypes = [NSMutableSet set];

		for (CFIndex i = 0; i < CFArrayGetCount(thumbnailableUTIs); i ++) {
			CFStringRef UTI = CFArrayGetValueAtIndex(thumbnailableUTIs, i);
			CFStringRef localMIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
			if (localMIMEType) {
				[mimeTypes addObject:(__bridge id _Nonnull)(localMIMEType)];
				CFRelease(localMIMEType);
			}
		}

		thumbnailableMIMETypes = [NSSet setWithSet:mimeTypes];
		CFRelease(thumbnailableUTIs);
	});

	return [thumbnailableMIMETypes containsObject:MIMEType];
}

- (void)deleteSidecarIfNecessary {
	if (self.fileName) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *fullPath = [self fullLocalPath];
		NSError *error = nil;
		BOOL isDir = NO;
		if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || isDir) {
			ApptentiveLogError(@"File attachment sidecar doesn't exist at path or is directory: %@, %d", fullPath, isDir);
			return;
		}
		if (![fm removeItemAtPath:fullPath error:&error]) {
			ApptentiveLogError(@"Error removing attachment at path: %@. %@", fullPath, error);
			return;
		}
		// Delete any thumbnails.
		NSArray *filenames = [fm contentsOfDirectoryAtPath:[[Apptentive sharedConnection].backend attachmentDirectoryPath] error:&error];
		if (!filenames) {
			ApptentiveLogError(@"Error listing attachments directory: %@", error);
		} else {
			for (NSString *filename in filenames) {
				if ([filename rangeOfString:self.fileName].location == 0) {
					NSString *thumbnailPath = [[self class] fullLocalPathForFilename:filename];

					if (![fm removeItemAtPath:thumbnailPath error:&error]) {
						ApptentiveLogError(@"Error removing attachment thumbnail at path: %@. %@", thumbnailPath, error);
						continue;
					}
				}
			}
		}
		_fileName = nil;
	}
}


@end
