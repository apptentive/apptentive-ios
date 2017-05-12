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
#import "ApptentiveMessageManager.h"
#import <MobileCoreServices/MobileCoreServices.h>


@implementation ApptentiveLegacyFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic message;
@dynamic remoteURL;
@dynamic remoteThumbnailURL;

+ (void)addMissingExtensionsInContext:(NSManagedObjectContext *)context andMoveToDirectory:(NSString *)newDirectory {
	ApptentiveAssertNotNil(context, @"Nil context when trying to add missing file extensions");
	if (context == nil) {
		return;
	}

	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ATFileAttachment"];

	NSError *error;
	NSArray *allAttachments = [context executeFetchRequest:fetchRequest error:&error];

	if (allAttachments == nil) {
		ApptentiveLogError(@"Unable to fetch file attachments: %@", error);
		return;
	}

	NSString *legacyDirectory = [Apptentive.shared.backend.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];

	for (ApptentiveLegacyFileAttachment *attachment in allAttachments) {
		if (attachment.localPath.length > 0) {
			NSString *legacyFilename = attachment.localPath;
			NSString *legacyPath = [legacyDirectory stringByAppendingString:legacyFilename];

			NSString *newFilename = legacyFilename;

			if (attachment.localPath.pathExtension.length == 0 && attachment.mimeType.length > 0) {
				[attachment.localPath stringByAppendingPathExtension:attachment.extension];
			}

			NSString *newPath = [newDirectory stringByAppendingPathComponent:newFilename];

			NSError *error;

			ApptentiveAssertNotNil(legacyPath, @"Legacy path must not be nil");
			ApptentiveAssertNotNil(newPath, @"New path must not be nil");

			if (legacyPath == nil) {
				ApptentiveLogError(@"Legacy path is nil for attachment %@", attachment);
				continue;
			}

			if (newPath == nil) {
				ApptentiveLogError(@"New path is nil for attachment %@", attachment);
				continue;
			}

			if ([[NSFileManager defaultManager] moveItemAtPath:legacyPath toPath:newPath error:&error]) {
				attachment.localPath = newFilename;
			} else {
				ApptentiveLogError(@"Unable to move attachment file %@ (error: %@)", newFilename, error);
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

@end
