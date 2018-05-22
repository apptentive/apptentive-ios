//
//  ApptentiveApptimize.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/8/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveApptimizeTestInfo;

extern NSNotificationName const ApptimizeTestsProcessedNotification;
extern NSNotificationName const ApptentiveApptimizeTestRunNotification;
extern NSString * const ApptentiveApptimizeTestNameUserInfoKey;
extern NSString * const ApptentiveApptimizeVariantNameUserInfoKey;

@interface ApptentiveApptimize : NSObject

/**
 @return `YES` if Apptimize SDK is integrated with the host app.
 */
+ (BOOL)isApptimizeSDKAvailable;

/**
 @return Returns the version number of the Apptimize library as a string formatted as *major.minor.build* (e.g., 3.0.1).
 */
+ (nullable NSString *)libraryVersion;

/**
 @return `YES` is Apptimize SDK library version is supported.
 */
+ (BOOL)isSupportedLibraryVersion;

+ (nullable NSDictionary<NSString *, ApptentiveApptimizeTestInfo*> *)testInfo;

@end

/**
 * Data container class that mimics `ApptimizeTestInfo`.
 * https://sdk.apptimize.com/ios/appledocs/appledoc-3.0.1/Protocols/ApptimizeTestInfo.html
 */
@interface ApptentiveApptimizeTestInfo : NSObject

@property (nonatomic, strong, readonly) NSString *testName;
@property (nonatomic, strong, readonly) NSString *enrolledVariantName;
@property (nonatomic, strong, readonly) NSString *testID;
@property (nonatomic, strong, readonly) NSNumber *enrolledVariantID;
@property (nonatomic, strong, readonly) NSDate *testStartedDate;
@property (nonatomic, strong, readonly) NSDate *testEnrolledDate;
@property (nonatomic, strong, readonly) NSNumber *cycle;
@property (nonatomic, strong, readonly) NSNumber *currentPhase;
@property (nonatomic, strong, readonly) NSNumber *participationPhase;
@property (nonatomic, readonly) BOOL userHasParticipated;

@end

NS_ASSUME_NONNULL_END
