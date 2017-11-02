//
//  ApptentiveInteractionsRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionsRequest.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveInteractionsRequest

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/%@/interactions", self.conversationIdentifier];
}

@end

NS_ASSUME_NONNULL_END
