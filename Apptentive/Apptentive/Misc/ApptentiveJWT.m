//
//  ApptentiveJWT.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJWT.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kApptentiveErrorDomain = @"com.apptentive";

inline static NSError *_createError(NSString *format, ...) {
	va_list ap;
	va_start(ap, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);

	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
	return [NSError errorWithDomain:kApptentiveErrorDomain code:0 userInfo:userInfo]; // TODO: better error code
}

static NSDictionary *_Nullable _decodeBase64Json(NSString *string, NSError **error) {
	string = [ApptentiveUtilities stringByPaddingBase64:string];

	NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
	if (data == nil) {
		if (error) {
			*error = _createError(@"Invalid base64 string: '%@'", string);
		}
		return nil;
	}

	NSError *jsonError = nil;
	id dictionary = [ApptentiveJSONSerialization JSONObjectWithData:data error:&jsonError];
	if (jsonError != nil) {
		ApptentiveLogError(@"Unable to parse json string: '%@'", error);
		if (error) {
			*error = _createError([jsonError localizedDescription]);
		}
		return nil;
	}

	if (![dictionary isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = _createError(@"Unexpected JWT payload class: '%@'", [dictionary class]);
		}
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

+ (nullable instancetype)JWTWithContentOfString:(NSString *)string error:(NSError **)error {
	if (string.length == 0) {
		if (error) {
			*error = _createError(@"Data string is nil or empty");
		}
		return nil;
	}

	NSArray<NSString *> *tokens = [string componentsSeparatedByString:@"."];
	if (tokens.count != 3) {
		if (error) {
			*error = _createError(@"Unable to create JWT: invalid data string '%@'", string);
		}
		return nil;
	}

	NSDictionary *header = _decodeBase64Json(tokens[0], error);
	NSString *alg = header[@"alg"];
	NSString *type = header[@"typ"];
	if (alg == nil || type == nil) {
		if (error) {
			*error = _createError(@"Unable to create JWT: invalid header '%@'", tokens[0]);
		}
		return nil;
	}

	NSDictionary *payload = _decodeBase64Json(tokens[1], error);
	if (payload == nil) {
		if (error) {
			*error = _createError(@"Unable to create JWT: invalid payload '%@'", tokens[1]);
		}
		return nil;
	}

	return [[self alloc] initWithAlg:alg type:type payload:payload];
}

@end

NS_ASSUME_NONNULL_END
