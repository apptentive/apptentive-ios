//
//  ApptentiveApptimize.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/8/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveApptimize.h"
#import "ApptentiveInvocation.h"

NSNotificationName const ApptimizeTestsProcessedNotification = @"ApptimizeTestsProcessedNotification";
NSNotificationName const ApptentiveApptimizeTestRunNotification = @"ApptimizeTestRunNotification";
NSString * const ApptentiveApptimizeTestNameUserInfoKey = @"ApptimizeTestName";
NSString * const ApptentiveApptimizeVariantNameUserInfoKey = @"ApptimizeVariantName";

static NSString * const kClassApptimize = @"Apptimize";
static NSString * const kMethodTestInfo = @"testInfo";
static NSString * const kMethodLibraryVersion = @"libraryVersion";

@interface ApptentiveApptimizeTestInfo ()

@property (nonatomic, strong, readwrite) NSString *testName;
@property (nonatomic, strong, readwrite) NSString *enrolledVariantName;
@property (nonatomic, strong, readwrite) NSString *testID;
@property (nonatomic, strong, readwrite) NSNumber *enrolledVariantID;
@property (nonatomic, strong, readwrite) NSDate *testStartedDate;
@property (nonatomic, strong, readwrite) NSDate *testEnrolledDate;
@property (nonatomic, strong, readwrite) NSNumber *cycle;
@property (nonatomic, strong, readwrite) NSNumber *currentPhase;
@property (nonatomic, strong, readwrite) NSNumber *participationPhase;
@property (nonatomic, readwrite) BOOL userHasParticipated;

@end

@implementation ApptentiveApptimize

+ (BOOL)isApptimizeSDKAvailable {
	return [ApptentiveInvocation classAvailable:kClassApptimize];
}

+ (nullable NSString *)libraryVersion {
	ApptentiveInvocation *apptimize = [ApptentiveInvocation fromClassName:kClassApptimize];
	if (apptimize == nil) {
		ApptentiveLogError(ApptentiveLogTagApptimize, @"Can't get Apptimize library version: class not found '%@'", kClassApptimize);
		return nil;
	}
	
	return [apptimize invokeSelector:kMethodLibraryVersion];
}

+ (BOOL)isSupportedLibraryVersion {
	NSString *libraryVersion = [self libraryVersion];
	if (libraryVersion == nil) {
		return NO;
	}
	
	NSArray *tokens = [libraryVersion componentsSeparatedByString:@"."];
	if (tokens.count != 3) {
		return NO;
	}
	
	NSUInteger major = [tokens[0] intValue];
	return major >= 3;
}

+ (nullable NSDictionary<NSString *, ApptentiveApptimizeTestInfo *> *)testInfo {
	ApptentiveInvocation *apptimize = [ApptentiveInvocation fromClassName:kClassApptimize];
	if (apptimize == nil) {
		ApptentiveLogError(ApptentiveLogTagApptimize, @"Can't list experiments: class not found '%@'", kClassApptimize);
		return nil;
	}
	
	NSDictionary *apptimizeTestsInfo = [apptimize invokeSelector:kMethodTestInfo];
	if (apptimizeTestsInfo == nil) {
		ApptentiveLogError(ApptentiveLogTagApptimize, @"Can't list experiments: [%@ %@] can't be resolved", kClassApptimize, kMethodTestInfo);
		return nil;
	}
	
	if (![apptimizeTestsInfo isKindOfClass:[NSDictionary class]]) {
		ApptentiveLogError(ApptentiveLogTagApptimize, @"Can't list experiments: [%@ %@] returned unexpected result %@", kClassApptimize, kMethodTestInfo, [apptimizeTestsInfo class]);
		return nil;
	}
	
	NSMutableDictionary<NSString *, ApptentiveApptimizeTestInfo *> *experiments = [NSMutableDictionary new];
	
	for (NSString *experimentName in apptimizeTestsInfo) {
		id experimentObj = apptimizeTestsInfo[experimentName];
		if (experimentObj == nil) {
			continue;
		}
		
		ApptentiveInvocation *experimentInvocation = [ApptentiveInvocation fromObject:experimentObj];
		
		ApptentiveApptimizeTestInfo *testInfo = [ApptentiveApptimizeTestInfo new];
		testInfo.testName = [experimentInvocation invokeSelector:@"testName"];
		testInfo.enrolledVariantName = [experimentInvocation invokeSelector:@"enrolledVariantName"];
		testInfo.testID = [experimentInvocation invokeSelector:@"testID"];
		testInfo.enrolledVariantID = [experimentInvocation invokeSelector:@"enrolledVariantID"];
		testInfo.testStartedDate = [experimentInvocation invokeSelector:@"testStartedDate"];
		testInfo.testEnrolledDate = [experimentInvocation invokeSelector:@"testEnrolledDate"];
		testInfo.cycle = [experimentInvocation invokeSelector:@"cycle"];
		testInfo.currentPhase = [experimentInvocation invokeSelector:@"currentPhase"];
		testInfo.participationPhase = [experimentInvocation invokeSelector:@"participationPhase"];
		testInfo.userHasParticipated = [[experimentInvocation invokeBoolSelector:@"userHasParticipated"] boolValue];
		
		experiments[experimentName] = testInfo;
	}
	
	return experiments;
}

@end

@implementation ApptentiveApptimizeTestInfo
@end
