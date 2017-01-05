//
//  ApptentiveRecord.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/3/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJSONModel.h"

@interface ApptentiveRecord : NSObject <ApptentiveJSONModel>

@property (readonly, nonatomic) NSDate *clientCreatedAt;
@property (readonly, nonatomic) NSTimeInterval clientCreatedAtUTCOffset;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *nonce;

- (instancetype)initWithNoncePrefix:(NSString *)noncePrefix payload:(NSDictionary *)payload;

@end
