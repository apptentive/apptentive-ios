//
//  ApptentiveRequest.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveRequest <NSObject>

@property (readonly, nonatomic) NSString *apiVersion;
@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSString *method;
@property (readonly, nonatomic) NSString *contentType;
@property (readonly, nullable, nonatomic) NSData *payload;
@property (readonly, nonatomic) BOOL encrypted;
@property (readonly, nonatomic) NSString *conversationIdentifier;

@end

NS_ASSUME_NONNULL_END
