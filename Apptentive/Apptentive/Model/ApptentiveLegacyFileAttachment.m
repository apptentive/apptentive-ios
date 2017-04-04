//
//  ApptentiveLegacyFileAttachment.m
//  Apptentive
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyFileAttachment.h"
#import "ApptentiveBackend.h"
#import "ApptentiveData.h"
#import "Apptentive_Private.h"
#import <MobileCoreServices/MobileCoreServices.h>


@implementation ApptentiveLegacyFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic message;
@dynamic remoteURL;
@dynamic remoteThumbnailURL;

+ (void)addMissingExtensions {
	NSArray *allAttachments = [ApptentiveData findEntityNamed:@"ATFileAttachment" withPredicate:[NSPredicate predicateWithValue:YES]];

	for (ApptentiveLegacyFileAttachment *attachment in allAttachments) {
		if (attachment.localPath.length && attachment.localPath.pathExtension.length == 0 && attachment.mimeType.length > 0) {
			NSString *newPath = [attachment.localPath stringByAppendingPathExtension:attachment.extension];
			NSError *error;
			if ([[NSFileManager defaultManager] moveItemAtPath:[self fullLocalPathForFilename:attachment.localPath] toPath:[self fullLocalPathForFilename:newPath] error:&error]) {
				attachment.localPath = newPath;
			} else {
				ApptentiveLogError(@"Unable to append extension to file %@ (error: %@)", newPath, error);
			}
		}
	}
}

- (NSString *)extension {
	NSString *_extension = nil;

	if (self.mimeType) {
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(self.mimeType), NULL);
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

+ (NSString *)fullLocalPathForFilename:(NSString *)filename {
	if (!filename) {
		return nil;
	}
	return [[[Apptentive sharedConnection].backend attachmentDirectoryPath] stringByAppendingPathComponent:filename];
}

@end

