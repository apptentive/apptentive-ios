//
//  ApptentiveLegacyFileAttachment.h
//  Apptentive
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ApptentiveLegacyMessage;


@interface ApptentiveLegacyFileAttachment : NSManagedObject
@property (copy, nonatomic) NSString *localPath;
@property (copy, nonatomic) NSString *mimeType; // starts w/ lowercase b/c Core Data is stupid
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *remoteURL;
@property (strong, nonatomic) NSURL *remoteThumbnailURL;
@property (strong, nonatomic) ApptentiveLegacyMessage *message;

+ (void)addMissingExtensions;

@end

