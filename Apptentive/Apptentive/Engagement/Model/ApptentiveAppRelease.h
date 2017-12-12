//
//  ApptentiveAppRelease.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveVersion;


/**
 An `ApptentiveAppRelease` represents a release of an application that has
 integrated the Apptentive SDK.
 */
@interface ApptentiveAppRelease : ApptentiveState

/**
 Indicates the type of app release. Will always be "ios".
 */
@property (readonly, strong, nonatomic) NSString *type;

/**
 The version object corresponding to the value of the
 `CFBundleShortVersionString` key in the application's `Info.plist` file.
 */
@property (readonly, strong, nonatomic) ApptentiveVersion *version;

/**
 The version object corresponding to the value of the `CFBundleVersion` key in
 the application's `Info.plist` file.
 */
@property (readonly, strong, nonatomic) ApptentiveVersion *build;


/**
 Indicates whether the file specified by the application's `appStoreRecieptURL`
 contains data.
 */
@property (readonly, assign, nonatomic) BOOL hasAppStoreReceipt;


/**
 Indicates whether the APPTENTIVE_DEBUG preprocessor directive is defined.
 */
@property (readonly, assign, nonatomic, getter=isDebugBuild) BOOL debugBuild;


/**
 Indicates whether the developer has accessed the style sheet object.
 */
@property (readonly, assign, nonatomic, getter=isOverridingStyles) BOOL overridingStyles;


/**
 Indicates whether the version has changed since the first release that 
 included the Apptentive SDK.
 */
@property (readonly, assign, nonatomic, getter=isUpdateVersion) BOOL updateVersion;


/**
 Indicates whether the build has changed since the first release that included
 the Apptentive SDK.
 */
@property (readonly, assign, nonatomic, getter=isUpdateBuild) BOOL updateBuild;


/**
 Records the time at which the SDK was first installed as part of the app.
 */
@property (readonly, strong, nonatomic) NSDate *timeAtInstallTotal;


/**
 Records the time at which the version changed to the current version.
 */
@property (readonly, strong, nonatomic) NSDate *timeAtInstallVersion;


/**
 Records the time at which the build changed to the current build.
 */
@property (readonly, strong, nonatomic) NSDate *timeAtInstallBuild;


/**
 The compiler used to compile the app.
 */
@property (readonly, strong, nonatomic) NSString *compiler;


/**
 The build number of the platform for which the app was built.
 */
@property (readonly, strong, nonatomic) NSString *platformBuild;


/**
 The name of the platform for which the app was built.
 */
@property (readonly, strong, nonatomic) NSString *platformName;


/**
 The version of the platform for which the app was built.
 */
@property (readonly, strong, nonatomic) NSString *platformVersion;


/**
 The (iOS) SDK build against which the app was linked.
 */
@property (readonly, strong, nonatomic) NSString *SDKBuild;


/**
 The (iOS) SDK name against which the app was linked.
 */
@property (readonly, strong, nonatomic) NSString *SDKName;


/**
 The Xcode version with which the app was built.
 */
@property (readonly, strong, nonatomic) NSString *Xcode;


/**
 The Xcode build with which the app was built.
 */
@property (readonly, strong, nonatomic) NSString *XcodeBuild;


/**
 Initializes an `ApptentiveAppRelease` object by inspecting the running app,
 primarily values in the app's `Info.plist` file.

 @return The new initialized app release object.
 */
- (instancetype)initWithCurrentAppRelease;

#pragma mark - Mutation

/**
 Records that the build of the current app release changed from the previous
 value. This will update the `timeAtInstallBuild` value and may update the
 `isUpdateBuild` value.
 */
- (void)resetBuild;

/**
 Records that the version of the current app release changed from the previous
 value. This will update the `timeAtInstallVersion` value and may update the
 `isUpdateVersion` value.
 */
- (void)resetVersion;

/**
 Records that the app developer has accessed the style sheet object.
 */
- (void)setOverridingStyles;

/**
 Copies values from another app release object that can't be observed from the current state of the app.

 @param otherAppRelease The app release object to copy values from
 */
- (void)copyNonholonomicValuesFrom:(ApptentiveAppRelease *)otherAppRelease;


/**
 Due to a bug some app release objects might be missing their timeAtInstall values.

 @param timeAtInstall The install time to fall back to if values are missing.
 */
- (void)updateMissingTimeAtInstallTo:(NSDate *)timeAtInstall;

@end

NS_ASSUME_NONNULL_END
