//
//  ApptentiveMessageGetRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageGetRequest.h"


@implementation ApptentiveMessageGetRequest

- (NSString *)path {
	NSString *path = @"conversations/<cid>/messages";

	if (self.lastMessageIdentifier != nil) {
		path = [path stringByAppendingFormat:@"?after_id=%@", self.lastMessageIdentifier];
	}

	return path;
}

@end
