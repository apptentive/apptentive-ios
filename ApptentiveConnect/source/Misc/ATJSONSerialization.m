//
//  ATJSONSerialization.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATJSONSerialization.h"

@implementation ATJSONSerialization
+ (NSData *)dataWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	return [NSJSONSerialization dataWithJSONObject:obj options:opterr error:error];
}

+ (NSString *)stringWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	NSData *d = [ATJSONSerialization dataWithJSONObject:obj options:opt error:error];
	if (!d) {
		return nil;
	}
	NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
	return s;
}

+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error {
	return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error {
	NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSObject *result = [ATJSONSerialization JSONObjectWithData:d error:error];
	return result;
}
@end
