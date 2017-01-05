//
//  ApptentiveSerialRequestAttachment.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ApptentiveSerialRequest;

@interface ApptentiveSerialRequestAttachment : NSManagedObject

@property (retain, nonatomic) NSString *mimeType;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *path;
@property (nonatomic, retain) ApptentiveSerialRequest *request;
@property (readonly, retain, nonatomic) NSData *fileData;

+ (instancetype)queuedAttachmentWithName:(NSString *)name path:(NSString *)path MIMEType:(NSString *)mimeType inContext:(NSManagedObjectContext *)context;

@end
