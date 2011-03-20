//
//  ATFeedbackTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATFeedbackTask.h"
#import "ATFeedback.h"

#define kATFeedbackTaskCodingVersion 1

@implementation ATFeedbackTask
@synthesize feedback;

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATFeedbackTaskCodingVersion) {
            self.feedback = [coder decodeObjectForKey:@"feedback"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATFeedbackTaskCodingVersion forKey:@"version"];
    [coder encodeObject:self.feedback forKey:@"feedback"];
}
@end
