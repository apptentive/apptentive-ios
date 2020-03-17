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
		@try {
			result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
		} @catch (NSException *exception) {
			ApptentiveAssertFail(@"Exception raised while unarchiving object: %@", exception);
			ApptentiveLogCrit(ApptentiveLogTagUtility, @"Exception raised while unarchiving object: %@", exception);
			return nil;
		}
	} else {
		result = [self legacyUnarchiveObjectWithData:data];
	}

	if (result == nil) {
		ApptentiveAssertFail(@"Unable to unarchive object: %@", error);
        ApptentiveLogCrit(ApptentiveLogTagUtility, @"Unable to unarchive object: %@", error);
    }

    return result;
}

+ (id)legacyUnarchiveObjectWithData:(NSData *)data {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		@try {
			NSData *result = [NSKeyedUnarchiver unarchiveObjectWithData:data];

			return result;
		} @catch (NSException *exception) {
			ApptentiveAssertFail(@"Exception raised while unarchiving object: %@", exception);
			ApptentiveLogCrit(ApptentiveLogTagUtility, @"Exception raised while unarchiving object: %@", exception);
			return nil;
		}
	#pragma clang diagnostic pop
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
