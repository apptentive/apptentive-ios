//
//  ApptentiveConfigurationRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConfigurationRequest.h"


@implementation ApptentiveConfigurationRequest

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/%@/configuration", self.conversationId];
}

@end
