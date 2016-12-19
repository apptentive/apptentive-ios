//
//  ApptentiveQueuedRequest.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ApptentiveFileAttachment;

@interface ApptentiveQueuedRequest : NSManagedObject

@property (strong, nonatomic) NSOrderedSet *attachments;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSData *payload;

+ (void)enqueueRequestWithPath:(NSString *)path payload:(NSDictionary *)payload attachments:(NSOrderedSet *)attachments inContext:(NSManagedObjectContext *)context;

@end
