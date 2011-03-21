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
@synthesize type, text, name, email, phone, screenshot, uuid, model, os_version, carrier;
- (id)init {
    if ((self = [super init])) {
        self.type = @"Feedback"; // TODO
        self.uuid = [[UIDevice currentDevice] uniqueIdentifier];
        self.model = [[UIDevice currentDevice] model];
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
            self.type = [coder decodeObjectForKey:@"type"];
            self.text = [coder decodeObjectForKey:@"text"];
            self.name = [coder decodeObjectForKey:@"name"];
            self.email = [coder decodeObjectForKey:@"email"];
            self.phone = [coder decodeObjectForKey:@"phone"];
            if ([coder containsValueForKey:@"screenshot"]) {
                NSData *data = [coder decodeObjectForKey:@"screenshot"];
                self.screenshot = [UIImage imageWithData:data];
            }
            self.uuid = [coder decodeObjectForKey:@"uuid"];
            self.model = [coder decodeObjectForKey:@"model"];
            self.os_version = [coder decodeObjectForKey:@"os_version"];
            self.carrier = [coder decodeObjectForKey:@"carrier"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kFeedbackCodingVersion forKey:@"version"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.phone forKey:@"phone"];
    if (self.screenshot) {
        [coder encodeObject:UIImagePNGRepresentation(self.screenshot) forKey:@"screenshot"];
    }
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.model forKey:@"model"];
    [coder encodeObject:self.os_version forKey:@"os_version"];
    [coder encodeObject:self.carrier forKey:@"carrier"];
}

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.text, @"text", self.name, @"name", self.email, @"email", self.phone, @"phone", self.screenshot, @"screenshot", nil];
}
@end
