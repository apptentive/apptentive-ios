//
//  ATFakeMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATFakeMessage.h"

#import "ATData.h"

@implementation ATFakeMessage

@dynamic body;
@dynamic subject;


+ (void)removeFakeMessages {
	@synchronized(self) {
		[ATData removeEntitiesNamed:@"ATFakeMessage" withPredicate:nil];
	}
}

@end
