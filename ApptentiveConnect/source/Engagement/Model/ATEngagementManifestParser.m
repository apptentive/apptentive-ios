//
//  ATEngagementManifestParser.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementManifestParser.h"
#import "ATJSONSerialization.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"
#import <UIKit/UIKit.h>

@implementation ATEngagementManifestParser

- (NSDictionary *)codePointInteractionsForEngagementManifest:(NSData *)jsonManifest {
	NSDictionary *codePointInteractions = nil;
	BOOL success = NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	id decodedObject = [ATJSONSerialization JSONObjectWithData:jsonManifest error:&error];
	if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
		success = YES;
		NSDictionary *jsonManifest = (NSDictionary *)decodedObject;
		NSDictionary *jsonCodePoints = [jsonManifest objectForKey:@"interactions"];
		
		NSMutableDictionary *codePoints = [[NSMutableDictionary alloc] init];
		for (NSString *codePointName in [jsonCodePoints allKeys]) {
			NSArray *jsonInteractions = [jsonCodePoints objectForKey:codePointName];
			
			NSMutableArray *interactions = [NSMutableArray array];
			for (NSDictionary *jsonInteraction in jsonInteractions) {
				ATInteraction *interaction = [ATInteraction interactionWithJSONDictionary:jsonInteraction];
				[interactions addObject:interaction];
			}
			[codePoints setObject:interactions forKey:codePointName];
		}
		
		codePointInteractions = codePoints;
	} else {
		[parserError release], parserError = nil;
		parserError = [error retain];
		success = NO;
	}
	
	[pool release], pool = nil;
	if (!success) {
		codePointInteractions = nil;
	} else {
		[codePointInteractions autorelease];
	}
	return codePointInteractions;
}

- (NSError *)parserError {
	return parserError;
}

- (void)dealloc {
	[parserError release], parserError = nil;
	[super dealloc];
}

@end
