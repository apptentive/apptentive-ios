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

/**
 The API version for which the payload was encoded.
 */
@property (strong, nonatomic) NSString *apiVersion;

/**
 The attachments (used for some messages) that should be included with the
 request.
 */
@property (strong, nonatomic) NSOrderedSet *attachments;

/**
 The date on which the request was created.
 */
@property (strong, nonatomic) NSDate *date;

/**
 An idenfier used to associate a request with a message.
 */
@property (strong, nonatomic) NSString *identifier;

/**
 The HTTP request method that shoud be used to make the request.
 */
@property (strong, nonatomic) NSString *method;

/**
 The path used to build the HTTP request URL.
 */
@property (strong, nonatomic) NSString *path;

/**
 The data that should be transmitted in the body of the HTTP request.
 */
@property (strong, nonatomic) NSData *payload;

/**
 Creates an enqueues a request with the specified parameters.

 @param path The path to use to build the URL.
 @param method The HTTP request method to use.
 @param payload The data to be transmitted in the body of the HTTP request.
 @param attachments Any attachments that should be included in the request.
 @param identifier An optional string that identifies a request.
 @param context The managed object context to use to create the request.
 */
+ (void)enqueueRequestWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload attachments:(NSOrderedSet *)attachments identifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;

@end
