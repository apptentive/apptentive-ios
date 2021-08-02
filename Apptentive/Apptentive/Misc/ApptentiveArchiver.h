//
//  ApptentiveArchiver.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/5/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveArchiver : NSObject

+ (BOOL)archiveRootObject:(NSObject *)rootObject toFile:(NSString *)path;
+ (nullable NSData *)archivedDataWithRootObject:(NSObject *)rootObject;

@end

NS_ASSUME_NONNULL_END
