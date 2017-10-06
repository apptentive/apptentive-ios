//
//  ApptentiveSerialRequestAttachment.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequestAttachment.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSerialRequestAttachment

@dynamic mimeType;
@dynamic name;
@dynamic path;
@dynamic request;

+ (instancetype)queuedAttachmentWithName:(NSString *)name path:(NSString *)path MIMEType:(NSString *)mimeType inContext:(NSManagedObjectContext *)context {
	ApptentiveSerialRequestAttachment *attachment = (ApptentiveSerialRequestAttachment *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedAttachment" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

	attachment.mimeType = mimeType;
	attachment.name = name ?: path.lastPathComponent;
	attachment.path = path;

	return attachment;
}

- (nullable NSData *)fileData {
	NSData *fileData = nil;
	if (self.path && [[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
		NSError *error = nil;
		fileData = [NSData dataWithContentsOfFile:self.path options:NSDataReadingMappedIfSafe error:&error];
		if (!fileData) {
			ApptentiveLogError(@"Unable to get contents of file path for uploading: %@", error);
		} else {
			return fileData;
		}
	}

	ApptentiveLogError(@"Missing sidecar file for %@", self);
	return nil;
}

@end

NS_ASSUME_NONNULL_END
