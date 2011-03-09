//
//  Base.m
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Base.h"


@implementation Base

@synthesize createdAt;
@synthesize updatedAt;

- initWithCoder: (NSCoder *)coder
{
    if ((self=[super init]))
    {
        self.createdAt = [coder decodeObjectForKey:@"createdAt"];
        self.updatedAt = [coder decodeObjectForKey:@"updatedAt"];
    }
    return self;
}

-(BOOL)buildDevice
{
    return YES;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:createdAt forKey:@"createdAt"];
    [coder encodeObject:updatedAt forKey:@"updatedAt"];
}

@end
