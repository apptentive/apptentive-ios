//
//  ATTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATTask.h"

#define kATTaskCodingVersion 1

@implementation ATTask
@synthesize finished;

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATTaskCodingVersion) {
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATTaskCodingVersion forKey:@"version"];
}

- (void)start {
    
}

- (void)stop {
    
}
@end
