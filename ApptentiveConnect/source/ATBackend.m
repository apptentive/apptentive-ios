//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATBackend.h"
#import "ATFeedback.h"

static ATBackend *sharedBackend = nil;

@implementation ATBackend

+ (ATBackend *)sharedBackend {
    @synchronized(self) {
        if (sharedBackend == nil) {
            sharedBackend = [[self alloc] init];
        }
    }
    return sharedBackend;
}

- (void)updateAPIKey:(NSString *)newAPIKey {
    //TODO
}

- (void)sendFeedback:(ATFeedback *)feedback {
    //TODO
}
@end
