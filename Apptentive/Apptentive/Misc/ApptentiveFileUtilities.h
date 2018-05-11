//
//  ApptentiveFileUtilities.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveFileUtilities : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)path;
+ (BOOL)directoryExistsAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path error:(NSError **)error;
+ (BOOL)deleteDirectoryAtPath:(NSString *)path error:(NSError **)error;
+ (nullable NSArray<NSString *> *)listFilesAtPath:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
