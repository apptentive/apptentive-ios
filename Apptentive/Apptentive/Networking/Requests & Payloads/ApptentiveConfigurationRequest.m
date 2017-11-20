//
//  ApptentiveConfigurationRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConfigurationRequest.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveConfigurationRequest

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/%@/configuration", self.conversationIdentifier];
}

@end

NS_ASSUME_NONNULL_END
