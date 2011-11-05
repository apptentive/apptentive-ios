//
//  ATSurveyTask.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyTask.h"
#import "ATSurveyResponse.h"
#import "ATWebClient+SurveyAdditions.h"

#define kATSurveyTaskCodingVersion 1

@interface ATSurveyTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATSurveyTask
@synthesize surveyResponse=surveyResponse$;

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATSurveyTaskCodingVersion) {
            self.surveyResponse = [coder decodeObjectForKey:@"surveyResponse"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATSurveyTaskCodingVersion forKey:@"version"];
    [coder encodeObject:self.surveyResponse forKey:@"surveyResponse"];
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)start {
    if (!request) {
        request = [[[ATWebClient sharedClient] requestForPostingSurveyResponse:self.surveyResponse] retain];
        request.delegate = self;
        [request start];
        self.inProgress = YES;
    }
}

- (void)stop {
    if (request) {
        request.delegate = nil;
        [request cancel];
        [request release], request = nil;
        self.inProgress = NO;
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
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
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
        self.lastErrorTitle = sender.errorTitle;
        self.lastErrorMessage = sender.errorMessage;
        NSLog(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
        [self stop];        
    }
}
@end

@implementation ATSurveyTask (Private)
- (void)setup {
    
}

- (void)teardown {
    [self stop];
}
@end
