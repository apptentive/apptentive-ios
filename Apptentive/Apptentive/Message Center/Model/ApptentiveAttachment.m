
//
//  ApptentiveAttachment.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAttachment.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

// TODO: see if we can remove/inject these dependencies
#import "ApptentiveBackend.h"
#import "ApptentiveDefines.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const FileNameKey = @"filename";
static NSString *const ContentTypeKey = @"contentType";
static NSString *const NameKey = @"name";
static NSString *const SizeKey = @"size";
static NSString *const RemoteURLKey = @"remoteURL";


@implementation ApptentiveAttachment

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			return nil;
		}

		_name = ApptentiveDictionaryGetString(JSON, @"original_name");

		_contentType = ApptentiveDictionaryGetString(JSON, @"content_type");
		if (_contentType.length == 0) {
			ApptentiveLogError(@"Can't init %@: content type is nil or empty", NSStringFromClass([self class]));
			return nil;
		}

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

- (nullable instancetype)initWithPath:(NSString *)path contentType:(NSString *)contentType name:(nullable NSString *)name {
	self = [super init];

	if (self) {
		APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(path);
		APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(contentType);

		BOOL isDirectory;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
			ApptentiveLogError(@"Can't init %@: file does not exist: %@", NSStringFromClass([self class]), path);
			return nil;
		}

		_filename = path.lastPathComponent;
		_attachmentDirectoryPath = path.stringByDeletingLastPathComponent;
		_contentType = contentType;
		_name = name;
	}

	return self;
}

- (nullable instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType name:(nullable NSString *)name attachmentDirectoryPath:(nonnull NSString *)attachmentDirectoryPath {
	self = [super init];

	// TODO: check input data
	if (self) {
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(data);
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(contentType);

		_contentType = contentType;
		_name = name;
		_attachmentDirectoryPath = attachmentDirectoryPath;

		NSURL *URL = [self permanentLocation];
		[data writeToURL:URL atomically:YES];
		_filename = URL.lastPathComponent;
		_size = [data length];
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		_filename = [coder decodeObjectOfClass:[NSString class] forKey:FileNameKey];
		_contentType = [coder decodeObjectOfClass:[NSString class] forKey:ContentTypeKey];
		_name = [coder decodeObjectOfClass:[NSString class] forKey:NameKey];
		_size = [coder decodeIntegerForKey:SizeKey];
		_remoteURL = [coder decodeObjectOfClass:[NSURL class] forKey:RemoteURLKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.filename forKey:FileNameKey];
	[coder encodeObject:self.contentType forKey:ContentTypeKey];
	[coder encodeObject:self.name forKey:NameKey];
	[coder encodeInteger:self.size forKey:SizeKey];
	[coder encodeObject:self.remoteURL forKey:RemoteURLKey];
}

- (NSURL *)permanentLocation {
	NSString *name = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:self.extension];
	return [NSURL fileURLWithPath:[self fullLocalPathForFilename:name]];
}

- (void)completeMoveToStorageFor:(NSURL *)storageLocation {
	[self deleteSidecarIfNecessary];
	_filename = storageLocation.lastPathComponent;
	_attachmentDirectoryPath = storageLocation.path.stringByDeletingLastPathComponent;
}

- (NSString *)fullLocalPath {
	return [self.attachmentDirectoryPath stringByAppendingPathComponent:self.filename];
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

- (nullable UIImage *)thumbnailOfSize:(CGSize)size {
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

- (void)deleteLocalContent {
	[self deleteSidecarIfNecessary];
	_filename = nil;
}

- (ApptentiveAttachment *)mergedWith:(ApptentiveAttachment *)attachmentFromServer {
	_remoteURL = attachmentFromServer.remoteURL;

	return self;
}

#pragma mark - Private

- (nullable NSString *)filenameForThumbnailOfSize:(CGSize)size {
	if (self.filename == nil) {
		return nil;
	}
	return [NSString stringWithFormat:@"%@_%dx%d_fit.jpeg", self.filename.stringByDeletingPathExtension, (int)floor(size.width), (int)floor(size.height)];
}

- (nullable UIImage *)createThumbnailOfSize:(CGSize)size {
	CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.fullLocalPath], NULL);
	if (src == NULL) {
		return nil;
	}

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
		NSString *fullThumbnailPath = [self fullLocalPathForFilename:filename];
		[UIImagePNGRepresentation(thumbnailImage) writeToFile:fullThumbnailPath atomically:YES];
	}

	return thumbnailImage;
}

- (nullable NSString *)fullLocalPathForFilename:(NSString *)filename {
	ApptentiveAssertNotEmpty(filename, @"Filename is required");
	ApptentiveAssertNotEmpty(self.attachmentDirectoryPath, @"Attachment directory path must be set");

	if (filename.length == 0 || self.attachmentDirectoryPath.length == 0) {
		ApptentiveLogError(@"Attempting to access attachment without attachment directory path set");
		return nil; // TODO: assertion?
	}

	return [self.attachmentDirectoryPath stringByAppendingPathComponent:filename];
}

+ (BOOL)canCreateThumbnailForMIMEType:(NSString *)MIMEType {
	static NSSet *thumbnailableMIMETypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  CFArrayRef thumbnailableUTIs = CGImageSourceCopyTypeIdentifiers();

	  NSMutableSet *mimeTypes = [NSMutableSet set];

	  for (CFIndex i = 0; i < CFArrayGetCount(thumbnailableUTIs); i++) {
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
	if (self.filename) {
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
		ApptentiveMessageManager *messageManager = Apptentive.shared.backend.conversationManager.messageManager;
		ApptentiveAssertNotNil(messageManager, @"Message manager is nil");
		if (!messageManager) {
			ApptentiveLogError(@"Error listing attachments directory: message manager is not initialized");
		} else {
			NSArray *filenames = [fm contentsOfDirectoryAtPath:messageManager.attachmentDirectoryPath error:&error];
			if (!filenames) {
				ApptentiveLogError(@"Error listing attachments directory: %@", error);
			} else {
				for (NSString *filename in filenames) {
					if ([filename hasPrefix:self.filename.stringByDeletingPathExtension]) {
						NSString *thumbnailPath = [self fullLocalPathForFilename:filename];

						if (![fm removeItemAtPath:thumbnailPath error:&error]) {
							ApptentiveLogError(@"Error removing attachment thumbnail at path: %@. %@", thumbnailPath, error);
							continue;
						}
					}
				}
			}
		}
		_filename = nil;
	}
}

@end


@implementation ApptentiveAttachment (QuickLook)

- (nullable NSString *)previewItemTitle {
	return self.name;
}

- (nullable NSURL *)previewItemURL {
	if (self.filename) {
		return [NSURL fileURLWithPath:self.fullLocalPath];
	} else {
		// Use fake path
		NSString *name = self.name ?: [[NSUUID UUID].UUIDString stringByAppendingPathExtension:self.extension];
		return [NSURL fileURLWithPath:[self fullLocalPathForFilename:name]];
	}
}

@end

NS_ASSUME_NONNULL_END
