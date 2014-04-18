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
	
	@autoreleasepool {
		NSError *error = nil;
		
		id decodedObject = [ATJSONSerialization JSONObjectWithData:jsonManifest error:&error];
		if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
			success = YES;
			NSDictionary *jsonManifest = (NSDictionary *)decodedObject;
			NSDictionary *jsonCodePoints = [jsonManifest objectForKey:@"interactions"];
			
#warning REMOVE; just for testing survey interaction.
#if APPTENTIVE_DEBUG
			NSMutableDictionary *added = [[jsonCodePoints mutableCopy] autorelease];
			[added setObject:@[[self surveyInteractionExample]] forKey:@"local#app#presentSurvey"];
			jsonCodePoints = added;
#endif
			
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
	}
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

#warning REMOVE
- (NSDictionary *)surveyInteractionExample {
	NSDictionary *interaction = @{@"id": @"526fe2836dd8bf546a00000c",
								  @"type": @"Survey",
								  @"priority": @3,
								  @"criteria": @{},
								  @"configuration": @{
										  @"name": @"What should we build?",
										  @"show_success_message": @YES,
										  @"success_message": @"Thank you for your input.",
										  @"description": @"Please help us figure this out!",
										  @"questions": @[
												  @{
													  @"id": @"52db59c27724c591ab00003e",
													  @"instructions": @"select one",
													  @"value": @"Which would you like to see first?",
													  @"type": @"multichoice",
													  @"required": @YES,
													  @"answer_choices": @[
															  @{
																  @"id": @"52db59c27724c591ab00003f",
																  @"value": @"Better user interface"
															  },
															  @{
																  @"id": @"52db59c27724c591ab000040",
																  @"value": @"Cloud support"
															  },
															  @{
																  @"id": @"52db59c27724c591ab000041",
																  @"value": @"Login with Facebook / Google / Twitter"
															  }
															  ]
													}
												  
												  ]
										  }
								  };
	
	return interaction;
}

@end
