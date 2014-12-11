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

- (NSString *)description {
	NSDictionary *description = @{@"interaction_id" : self.interactionID ?: [NSNull null],
								  @"priority" : [NSNumber numberWithInteger:self.priority] ?: [NSNull null],
								  @"criteria" : self.criteria ?: [NSNull null]};
	
	return [description description];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.interactionID = [coder decodeObjectForKey:@"interactionID"];
		self.priority = [coder decodeIntegerForKey:@"priority"];
		self.criteria = [coder decodeObjectForKey:@"criteria"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.interactionID forKey:@"interactionID"];
	[coder encodeInteger:self.priority forKey:@"priority"];
	[coder encodeObject:self.criteria forKey:@"criteria"];
}

- (id)copyWithZone:(NSZone *)zone {
	ATInteractionInvocation *copy = [[ATInteractionInvocation alloc] init];
	
	if (copy) {
		copy.interactionID = self.interactionID;
		copy.priority = self.priority;
		copy.criteria = self.criteria;
	}
	
	return copy;
}

@end
