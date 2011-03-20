//
//  ATFeedback.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATFeedback.h"

#define kFeedbackCodingVersion 1

@implementation ATFeedback
@synthesize text, name, email, phone, screenshot;
- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (void)dealloc {
    self.text = nil;
    self.name = nil;
    self.email = nil;
    self.phone = nil;
    self.screenshot = nil;
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kFeedbackCodingVersion) {
            self.text = [coder decodeObjectForKey:@"text"];
            self.name = [coder decodeObjectForKey:@"name"];
            self.email = [coder decodeObjectForKey:@"email"];
            self.phone = [coder decodeObjectForKey:@"phone"];
            self.screenshot = [coder decodeObjectForKey:@"screenshot"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kFeedbackCodingVersion forKey:@"version"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.phone forKey:@"phone"];
    [coder encodeObject:self.screenshot forKey:@"screenshot"];
}

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.text, @"text", self.name, @"name", self.email, @"email", self.phone, @"phone", self.screenshot, @"screenshot", nil];
}
@end
