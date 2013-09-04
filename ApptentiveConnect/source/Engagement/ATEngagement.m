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
	[[ATEngagementBackend sharedBackend] codePointWasEngaged:codePoint];
	
	ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForCodePoint:codePoint];
	if (interaction) {
		[[ATEngagementBackend sharedBackend] presentInteraction:interaction];
		
		[[ATEngagementBackend sharedBackend] interactionWasEngaged:interaction];
	}
	else {
		ATLogInfo(@"No valid Apptentive interactions found for code point: %@", codePoint);
	}
}

@end
