//
//  ATFeedbackTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATFeedbackTask.h"
#import "ATFeedback.h"
#import "ATWebClient.h"

#define kATFeedbackTaskCodingVersion 1

@interface ATFeedbackTask (Private)
- (void)setup;
- (void)teardown;
- (void)feedbackDidLoad:(ATWebClient *)sender result:(id)result;
@end

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

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)start {
    if (!client) {
        client = [[ATWebClient alloc] initWithTarget:self action:@selector(feedbackDidLoad:result:)];
        client.returnType = ATWebClientReturnTypeString;
        [client postFeedback:self.feedback];
    }
    
}

- (void)stop {
    if (client) {
        [client cancel];
        [client release];
        client = nil;
    }
}
@end

@implementation ATFeedbackTask (Private)
- (void)setup {
    
}

- (void)teardown {
    if (client) {
        [client cancel];
        [client release];
        client = nil;
    }
}

- (void)feedbackDidLoad:(ATWebClient *)sender result:(id)result {
	@synchronized (self) {
        if (sender.failed) {
            self.failed = YES;
            NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
            [self stop];
        } else {
            self.finished = YES;
        }
	}
}
@end
