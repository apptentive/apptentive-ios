//
//  ApptentiveConversationRequest.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveAppInstall;


@interface ApptentiveConversationRequest : ApptentiveRequest

@property (readonly, nonatomic) id<ApptentiveAppInstall> appInstall;

- (nullable instancetype)initWithAppInstall:(id<ApptentiveAppInstall>)appInstall;

- (NSDictionary *)JSONDictionary;

@end

NS_ASSUME_NONNULL_END
