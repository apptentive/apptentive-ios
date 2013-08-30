//
//  ATEngagement.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagement.h"
#import "ATEngagementBackend.h"
#import "ATInteraction.h"

@implementation ATEngagement

+ (void)engage:(NSString *)codePoint {
	ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForCodePoint:codePoint];
	if (interaction) {
		ATLogInfo(@"Valid interaction %@ found for code point: %@", interaction.identifier, codePoint);
		
		// TODO: launch interaction
	}
	else {
		ATLogInfo(@"No valid interactions found for code point: %@", codePoint);
	}
}

@end
