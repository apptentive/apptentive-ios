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
#import "ATConnect_Debugging.h"
#import "ATInteractionInvocation.h"

@implementation ATEngagementManifestParser



- (NSDictionary *)targetsAndInteractionsForEngagementManifest:(NSData *)jsonManifest {
	NSMutableDictionary *targets = [NSMutableDictionary dictionary];
	NSMutableDictionary *interactions = [NSMutableDictionary dictionary];
	
	BOOL success = NO;
	
	@autoreleasepool {
		@try {
			NSError *error = nil;
			
			id decodedObject = [ATJSONSerialization JSONObjectWithData:jsonManifest error:&error];
			if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *jsonManifest = (NSDictionary *)decodedObject;
				
				// Targets
				NSDictionary *targetsDictionary = jsonManifest[@"targets"];
				for (NSString *event in [targetsDictionary allKeys]) {
					NSArray *invocationsJSONArray = targetsDictionary[event];
					NSArray *invocationsArray = [ATInteractionInvocation invocationsWithJSONArray:invocationsJSONArray];
					[targets setObject:invocationsArray forKey:event];
				}
				
				// Interactions
				NSArray *interactionsArray = jsonManifest[@"interactions"];
				for (NSDictionary *interactionDictionary in interactionsArray) {
					ATInteraction *interactionObject = [ATInteraction interactionWithJSONDictionary:interactionDictionary];
					[interactions setObject:interactionObject forKey:interactionObject.identifier];
				}
				
				success = YES;
			} else {
				[parserError release], parserError = nil;
				parserError = [error retain];
				success = NO;
			}
		}
		@catch (NSException *exception) {
			ATLogError(@"Exception parsing engagement manifest: %@", exception);
			success = NO;
		}
	}
	
	NSDictionary *targetsAndInteractions = nil;
	if (success) {
		targetsAndInteractions = @{@"targets": targets,
								   @"interactions": interactions};
	}
	
	return targetsAndInteractions;
}

- (NSError *)parserError {
	return parserError;
}

- (void)dealloc {
	[parserError release], parserError = nil;
	[super dealloc];
}

@end
