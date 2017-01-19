//
//  ApptentiveSerialRequestAttachment.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ApptentiveSerialRequest;


/**
 An `ApptentiveSerialRequestAttachment` represents an attachment to a message
 sent from Message Center.

 It includes the information needed to construct part of a multipart request
 corresponding to the attachment.
 */
@interface ApptentiveSerialRequestAttachment : NSManagedObject

@property (retain, nonatomic) NSString *mimeType;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *path;
@property (retain, nonatomic) ApptentiveSerialRequest *request;
@property (readonly, retain, nonatomic) NSData *fileData;

+ (instancetype)queuedAttachmentWithName:(NSString *)name path:(NSString *)path MIMEType:(NSString *)mimeType inContext:(NSManagedObjectContext *)context;

@end
