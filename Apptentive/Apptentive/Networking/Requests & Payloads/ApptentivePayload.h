//
//  ApptentivePayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentivePayload : NSObject

@property (readonly, nonatomic) NSString *apiVersion;
@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSString *method;
@property (readonly, nonatomic) NSString *contentType;
@property (readonly, nullable, nonatomic) NSData *payload;
@property (readonly, nonatomic) BOOL encrypted;

@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) NSString *containerName;
@property (readonly, nonatomic) NSDictionary *contents;

@property (readonly, nullable, nonatomic) NSArray *attachments;
@property (readonly, nullable, nonatomic) NSString *localIdentifier;

@property (nullable, nonatomic) NSData *encryptionKey;
@property (nullable, nonatomic) NSString *token;

- (instancetype)initWithCreationDate:(NSDate *)creationDate;
- (NSData *)marshalForSending;

@end

NS_ASSUME_NONNULL_END
