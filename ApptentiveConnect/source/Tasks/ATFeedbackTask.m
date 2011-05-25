//
//  ATFeedbackTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedbackTask.h"
#import "ATFeedback.h"
#import "ATWebClient.h"

#define kATFeedbackTaskCodingVersion 1

@interface ATFeedbackTask (Private)
- (void)setup;
- (void)teardown;
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
    if (!request) {
        request = [[[ATWebClient sharedClient] requestForPostingFeedback:self.feedback] retain];
        [request start];
    }
}

- (void)stop {
    if (request) {
        request.delegate = nil;
        [request cancel];
        [request release], request = nil;
    }
}

- (float)percentComplete {
    if (request) {
        return [request percentageComplete];
    } else {
        return 0.0f;
    }
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(id)result {
    @synchronized(self) {
        self.finished = YES;
    }
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
    // pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
    @synchronized(self) {
        self.failed = YES;
        NSLog(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
        [self stop];        
    }
}
@end

@implementation ATFeedbackTask (Private)
- (void)setup {
    
}

- (void)teardown {
    [self stop];
}
@end
