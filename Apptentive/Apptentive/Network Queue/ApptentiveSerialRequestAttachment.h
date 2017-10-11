//
//  ApptentiveSerialRequestAttachment.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveSerialRequest;


/**
 An `ApptentiveSerialRequestAttachment` represents an attachment to a message
 sent from Message Center.

 It includes the information needed to construct part of a multipart request
 corresponding to the attachment.
 */
@interface ApptentiveSerialRequestAttachment : NSManagedObject

/**
 The MIME type of the attachment.
 */
@property (retain, nonatomic) NSString *mimeType;

/**
 The name of the attachment.
 */
@property (retain, nonatomic) NSString *name;

/**
 The local path where the attachment is stored.
 */
@property (retain, nonatomic) NSString *path;

/**
 The request information associated with the attachment.
 */
@property (retain, nonatomic) ApptentiveSerialRequest *request;

/**
 The file data for the attachment.
 */
@property (readonly, nullable, retain, nonatomic) NSData *fileData;

/**
 Creates and returns a new attachment with the specified parameters.

 @param name The name of the attachment.
 @param path The local path of the attachment file.
 @param mimeType The MIME type of the attachment.
 @param context The managed object context in which to create the attachment.
 @return The newly-created attachment.
 */
+ (instancetype)queuedAttachmentWithName:(NSString *)name path:(NSString *)path MIMEType:(NSString *)mimeType inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
