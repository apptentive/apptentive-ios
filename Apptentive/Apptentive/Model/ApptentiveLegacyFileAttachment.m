//
//  ApptentiveLegacyFileAttachment.m
//  Apptentive
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyFileAttachment.h"
#import "ApptentiveLegacyMessage.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"


@implementation ApptentiveLegacyFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic message;
@dynamic remoteURL;
@dynamic remoteThumbnailURL;

+ (void)deleteCachedAttachmentsInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATFileAttachment"];

    NSError *error;
    NSArray *cachedAttachments = [context executeFetchRequest:request error:&error];
    
    ApptentiveAssertNotNil(cachedAttachments, @"Error fetching cached attachments: %@", error);
    
    NSMutableSet *filesToSave = [NSMutableSet set];
    for (ApptentiveLegacyFileAttachment *attachment in cachedAttachments) {
        NSInteger pendingState = attachment.message.pendingState.integerValue;
        
        if (pendingState == ATPendingMessageStateSending || pendingState == ATPendingMessageStateError) {
            [filesToSave addObject:attachment.localPath];
        } else {
            [context deleteObject:attachment];
        }
    }
    
    NSArray *cachedAttachmentFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self legacyDirectory] error:&error];
    
    ApptentiveAssertNotNil(cachedAttachmentFiles, @"Unable to get contents of attachments directory (%@): %@", [self legacyDirectory], error);
    
    for (NSString *attachmentFile in cachedAttachmentFiles) {
        if ([filesToSave containsObject:attachmentFile]) {
            continue;
        }
        
        NSString *fullPath = [[self legacyDirectory] stringByAppendingPathComponent:attachmentFile];
        if (![[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error]) {
            ApptentiveLogError(@"Unable to remove cached attachment file (%@): %@", fullPath, error);
        }
    }
    
    NSString *draftAttachmentsPath = [Apptentive.shared.backend.supportDirectoryPath stringByAppendingPathComponent:@"DraftAttachments"];

    if (![[NSFileManager defaultManager] removeItemAtPath:draftAttachmentsPath error:&error]) {
        ApptentiveLogError(@"Unable to delete draft attachments file (%@): %@", draftAttachmentsPath, error);
    }
}

+ (NSString *)legacyDirectory {
    return [Apptentive.shared.backend.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];
}

@end
