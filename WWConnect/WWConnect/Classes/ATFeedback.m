//
//  ATFeedback.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATFeedback.h"

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

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.text, @"text", self.name, @"name", self.email, @"email", self.phone, @"phone", self.screenshot, @"screenshot", nil];
}
@end
