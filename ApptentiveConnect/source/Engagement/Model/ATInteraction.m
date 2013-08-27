//
//  ATInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteraction.h"

@implementation ATInteraction

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.identifier = [jsonDictionary objectForKey:@"id"];
	interaction.priority = [[jsonDictionary objectForKey:@"priority"] intValue];
	interaction.type = [jsonDictionary objectForKey:@"type"];
	interaction.configuration = [jsonDictionary objectForKey:@"configuration"];
	interaction.conditions = [jsonDictionary objectForKey:@"conditions"];
	return [interaction autorelease];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.identifier = [coder decodeObjectForKey:@"identifier"];
		self.priority = [coder decodeIntForKey:@"priority"];
		self.type = [coder decodeObjectForKey:@"type"];
		self.configuration = [coder decodeObjectForKey:@"configuration"];
		self.conditions = [coder decodeObjectForKey:@"conditions"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	//TODO: versions. See Surveys
	//[coder encodeInt:kATInteractionVersion forKey:@"version"];
	
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeInt:self.priority forKey:@"priority"];
	[coder encodeObject:self.type forKey:@"type"];
	[coder encodeObject:self.configuration forKey:@"configuration"];
	[coder encodeObject:self.conditions forKey:@"conditions"];
}

@end
