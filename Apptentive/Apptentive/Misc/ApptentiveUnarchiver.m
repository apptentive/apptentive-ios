//
//  ApptentiveUnarchiver.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/5/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveUnarchiver.h"

@implementation ApptentiveUnarchiver

+ (id)unarchivedObjectOfClass:(Class)klass fromData:(NSData *)data {
	return [self unarchivedObjectOfClasses:[NSSet setWithObject:klass] fromData:data];
}

+ (nullable id)unarchivedObjectOfClass:(Class)klass fromFile:(NSString *)path {
	return [self unarchivedObjectOfClasses:[NSSet setWithObject:klass] fromFile:path];
}

+ (id)unarchivedObjectOfClasses:(NSSet<Class>*)classes fromData:(NSData *)data {
    NSError *error = nil;
	id result = nil;

	if (@available(iOS 11.0, *)) {
		result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
	}

    if (result == nil) {
        ApptentiveLogError(ApptentiveLogTagUtility, @"Unable to unarchive object: %@", error);
    }

    return result;
}

+ (nullable id)unarchivedObjectOfClasses:(NSSet<Class> *)classes fromFile:(nonnull NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];

	if (data) {
		return [self unarchivedObjectOfClasses:classes fromData:data];
	} else {
		ApptentiveLogWarning(@"File %@ was not found", path);
		return nil;
	}
}

@end
