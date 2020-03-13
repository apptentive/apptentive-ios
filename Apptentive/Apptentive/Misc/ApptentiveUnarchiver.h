//
//  ApptentiveUnarchiver.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/5/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveUnarchiver : NSObject

+ (id)unarchivedObjectOfClass:(Class)klass fromData:(NSData *)data;
+ (nullable id)unarchivedObjectOfClass:(Class)klass fromFile:(NSString *)path;

+ (id)unarchivedObjectOfClasses:(NSSet<Class>*)classes fromData:(NSData *)data;
+ (nullable id)unarchivedObjectOfClasses:(NSSet<Class>*)classes fromFile:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
