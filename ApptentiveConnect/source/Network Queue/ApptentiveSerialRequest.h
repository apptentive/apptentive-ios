//
//  ApptentiveSerialRequest.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ApptentiveFileAttachment;


/**
 An `ApptentiveSerialRequest` instance encapsulates the data used to make a
 network request in an `ApptentiveSerialNetworkQueue`. Instance are created
 using the
 `+enqueueRequestWithPath:method:payload:attachments:identifier:inContext:`
 method.

 The API version is included because the payload encoding may change, so any
 migrated requests (encoded to the previous version's specifications) should
 be sent with the matching API version.
 */
@interface ApptentiveSerialRequest : NSManagedObject

@property (strong, nonatomic) NSString *apiVersion;
@property (strong, nonatomic) NSOrderedSet *attachments;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *method;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSData *payload;

+ (void)enqueueRequestWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload attachments:(NSOrderedSet *)attachments identifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;

@end
