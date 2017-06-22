//
//  ApptentiveLoginRequest.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveNewLoginRequest : ApptentiveRequest

@property (readonly, nonatomic) NSString *token;

- (nullable instancetype)initWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
