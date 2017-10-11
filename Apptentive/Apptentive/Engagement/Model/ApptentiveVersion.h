//
//  ApptentiveVersion.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/17/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An `AppteniveVersion` represents a version number. In the preferred case, the
 version consists of one to three nonnegative integers separated by periods.
 These will be parsed into the major, minor, and patch values. If the minor
 and/or patch versions are not specified, they will be assumed to be zero for
 purposes of equality with other version objects.
 
 If the version uses a different format, the major, minor, and patch numbers
 will be set to negative one, and equality will be determined by the whether
 the version string is an exact match.
 
 If the version argument is nil or empty, it will default to 0.0.0.
 */
@interface ApptentiveVersion : ApptentiveState

/**
 The major version of the version object, corresponding to the first integer.
 Set to -1 if the version is initialized with a non-conforming string.
 */
@property (readonly, nonatomic) NSInteger major;

/**
 The minor version of the version object, corresponding to the second integer.
 Set to 0 if no minor version is specified. Set to -1 if the version is
 initialized with a non-conforming string.
 */
@property (readonly, nonatomic) NSInteger minor;

/**
 The patch version of the version object, corresponding to the second integer.
 Set to 0 if no patch version is specified. Set to -1 if the version is
 initialized with a non-conforming string.
 */
@property (readonly, nonatomic) NSInteger patch;

/**
 The string used to initialize the version.
 */
@property (readonly, nonatomic) NSString *versionString;

/**
 Initailizes a new version object corresponding to the specified string.

 @param versionString The string used to specify the version.
 @return The newly-initialized version object.
 */
- (instancetype)initWithString:(NSString *)versionString;


/**
 Returns YES if the version parameter is equal to the receiver. For conforming
 versions, it returns true if the major, minor, and patch versions are equal. 

 For non-conforming versions, it returns true if the receiver's `versionString`
 is an exact match for the parameter's `versionString`.

 @param version The version to compare against the receiver.
 @return Whether the two versions are equal, as described above.
 */
- (BOOL)isEqualToVersion:(ApptentiveVersion *)version;

@end

NS_ASSUME_NONNULL_END
