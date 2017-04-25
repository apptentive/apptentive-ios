//
//  ApptentivePayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentivePayload : NSObject <ApptentiveRequest>

@property (readonly, nonatomic) NSString *containerName;
@property (readonly, nonatomic) NSDictionary *contents;

@property (readonly, nullable, nonatomic) NSArray *attachments;
@property (readonly, nullable, nonatomic) NSString *localIdentifier;

@end

NS_ASSUME_NONNULL_END
