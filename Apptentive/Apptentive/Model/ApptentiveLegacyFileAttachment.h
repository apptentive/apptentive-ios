//
//  ApptentiveLegacyFileAttachment.h
//  Apptentive
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveLegacyMessage;


@interface ApptentiveLegacyFileAttachment : NSManagedObject

@property (copy, nonatomic) NSString *localPath;
@property (copy, nonatomic) NSString *mimeType; // starts w/ lowercase b/c Core Data is stupid
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *remoteURL;
@property (strong, nonatomic) NSURL *remoteThumbnailURL;
@property (strong, nonatomic) ApptentiveLegacyMessage *message;

@property (readonly, nonatomic) NSString *extension;

@end

NS_ASSUME_NONNULL_END
