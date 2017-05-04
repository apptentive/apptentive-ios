//
//  ApptentiveJWT.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJWT.h"

static NSDictionary * _Nullable _decodeBase64Json(NSString *string) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
    if (data == nil) {
        ApptentiveLogError(@"Invalid base64 string: '%@'", string);
        return nil;
    }
    
    NSError *error = nil;
    id dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil) {
        ApptentiveLogError(@"Unable to parse json string: '%@'", error);
        return nil;
    }
    
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        ApptentiveLogError(@"Unexpected JWT payload class: '%@'", [dictionary class]);
        return nil;
    }
    
    return dictionary;
}

@implementation ApptentiveJWT

- (nullable instancetype)initWithAlg:(NSString *)alg type:(NSString *)type payload:(NSDictionary *)payload {
    self = [super init];
    if (self) {
        if (alg.length == 0) {
            ApptentiveLogError(@"Unable to create JWT: 'alg' is nil or empty");
            return nil;
        }
        if (type.length == 0) {
            ApptentiveLogError(@"Unable to create JWT: 'type' is nil or empty");
            return nil;
        }
        
        if (payload == nil) {
            ApptentiveLogError(@"Unable to create JWT: 'payload' is nil");
            return nil;
        }
        
        _alg = [alg copy];
        _type = [type copy];
        _payload = [payload copy];
    }
    return self;
}

+ (nullable instancetype)JWTWithContentOfString:(NSString *)string {
    if (string.length == 0) {
        ApptentiveLogError(@"Unable to create JWT: data string is nil or empty");
        return nil;
    }
    
    NSArray<NSString *> *tokens = [string componentsSeparatedByString:@"."];
    if (tokens.count != 3) {
        ApptentiveLogError(@"Unable to create JWT: invalid data string '%@'", string);
        return nil;
    }
    
    NSDictionary *header = _decodeBase64Json(tokens[0]);
    NSString *alg = header[@"alg"];
    NSString *type = header[@"typ"];
    if (alg == nil || type == nil) {
        ApptentiveLogError(@"Unable to create JWT: invalid header '%@'", tokens[0]);
        return nil;
    }
    
    NSDictionary *payload = _decodeBase64Json(tokens[1]);
    if (payload == nil) {
        ApptentiveLogError(@"Unable to create JWT: invalid payload '%@'", tokens[1]);
        return nil;
    }
    
    return [[self alloc] initWithAlg:alg type:type payload:payload];
}

@end
