//
//  ATInteractionInvocation.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionInvocation.h"

@implementation ATInteractionInvocation

+ (ATInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteractionInvocation *invocation = [[[ATInteractionInvocation alloc] init] autorelease];
	invocation.interactionID = jsonDictionary[@"interaction_id"];
	invocation.priority = [jsonDictionary[@"priority"] integerValue];
	invocation.criteria = jsonDictionary[@"criteria"];
	
	return invocation;
}

@end
