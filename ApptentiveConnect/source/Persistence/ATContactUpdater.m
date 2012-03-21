//
//  ATContactUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/23/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATContactUpdater.h"
#import "ATContactStorage.h"
#import "ATWebClient.h"
#import "JSONKit.h"

NSString * const ATContactUpdaterFinished = @"ATContactUpdaterFinished";

@interface ATContactUpdater (Private)
- (void)processResult:(NSData *)jsonContactInfo;
@end

@implementation ATContactUpdater
- (void)dealloc {
    [self cancel];
    [super dealloc];
}

- (void)update {
    [self cancel];
    request = [[[ATWebClient sharedClient] requestForGettingContactInfo] retain];
    request.delegate = self;
    [request start];
}

- (void)cancel {
    if (request) {
        request.delegate = nil;
        [request cancel];
        [request release], request = nil;
    }
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
    @synchronized (self) {
        if ([result isKindOfClass:[NSData class]]) {
            [self processResult:(NSData *)result];
        } else {
            NSLog(@"Contact result is not NSData!");
        }
    }
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
    // pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		// Save anyway, so we don't keep trying.
		ATContactStorage *storage = [ATContactStorage sharedContactStorage];
		[storage save];
	}
}
@end

@implementation ATContactUpdater (Private)
- (void)processResult:(NSData *)jsonContactInfo {
    ATContactParser *parser = [[ATContactParser alloc] init];
    if ([parser parse:jsonContactInfo]) {
        ATContactStorage *storage = [ATContactStorage sharedContactStorage];
        if (parser.name) storage.name = parser.name;
        if (parser.email) storage.email = parser.email;
        if (parser.phone) storage.phone = parser.phone;
        [storage save];
        [[NSNotificationCenter defaultCenter] postNotificationName:ATContactUpdaterFinished object:self];
    }
    [parser release], parser = nil;
}
@end

@implementation ATContactParser
@synthesize name, email, phone;

- (BOOL)parse:(NSData *)jsonContactInfo {
    BOOL success = NO;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    self.name = nil;
    self.phone = nil;
    self.email = nil;
    JSONDecoder *decoder = [JSONDecoder decoder];
    NSError *error = nil;
    id decodedObject = [decoder objectWithData:jsonContactInfo error:&error];
    if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
        success = YES;
        NSDictionary *values = (NSDictionary *)decodedObject;
        
        NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"name", @"email", @"email", @"phone", @"phone_number", nil];
        
        for (NSString *key in keyMapping) {
            NSString *ivarName = [keyMapping objectForKey:key];
            NSObject *value = [values objectForKey:key];
            if (value && [value isKindOfClass:[NSString class]]) {
                [self setValue:value forKey:ivarName];
            }
        }
    } else {
        parserError = [error retain];
        success = NO;
    }
    
    [pool release], pool = nil;
    return success;
}

- (NSError *)parserError {
    return parserError;
}

- (void)dealloc {
    self.name = nil;
    self.email = nil;
    self.phone = nil;
    [parserError release], parserError = nil;
    [super dealloc];
}
@end

