//
//  ApptentiveMessageSendRequest.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveSerialRequest;

/* The purpose of this class is to wrap a request pulled from the
 database that has attachments and convert its payload to a 
 multipart request payload. */

@interface ApptentiveMessageSendRequest : ApptentiveRequest

@property (readonly, nonatomic) ApptentiveSerialRequest *request;
@property (readonly, nonatomic) NSString *messageIdentifier;

- (instancetype)initWithRequest:(ApptentiveSerialRequest *)request;

@end

NS_ASSUME_NONNULL_END
