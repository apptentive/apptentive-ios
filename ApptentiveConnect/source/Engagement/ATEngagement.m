//
//  ATEngagement.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagement.h"
#import "ATEngagementBackend.h"

@implementation ATEngagement

+ (void)engage:(NSString *)codePoint {
	NSArray *interactions = [[ATEngagementBackend sharedBackend] interactionsForCodePoint:codePoint];
	NSLog(@"Codepoint `%@` has %i interactions", codePoint, interactions.count);
}

@end
