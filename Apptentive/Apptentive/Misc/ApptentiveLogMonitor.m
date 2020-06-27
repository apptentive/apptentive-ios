//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJSONSerialization.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveJWT.h"
#import "ApptentiveLogMonitor.h"
#import "ApptentiveLogMonitorSession.h"
#import "ApptentiveSafeCollections.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveFileUtilities.h"
#import "ApptentiveDispatchQueue.h"
#import "ApptentiveUtilities.h"


// These constants are defined in Apptentive-Private.h but the compiler is "unhappy" if
// this file is imported here (TODO: figure it out)
extern NSString *ApptentiveLocalizedString(NSString *key, NSString *comment);
extern NSNotificationName _Nonnull const ApptentiveManifestRawDataDidReceiveNotification;
extern NSString *_Nonnull const ApptentiveManifestRawDataKey;

static NSString *const LogFileName = @"apptentive-log.txt";
static NSString *const DebugTextHeader = @"com.apptentive.debug:";

static ApptentiveLogMonitorSession * _currentSession;

@implementation ApptentiveLogMonitor

#pragma mark -
#pragma mark Session

+ (void)startSessionWithQueue:(nonnull ApptentiveDispatchQueue *)queue {
	if (queue == NULL) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: no dispatch queue.");
		return;
	}

	// all the initialization should happen on the dedicated queue
	[queue dispatchAsync:^{
		@try {
			// register observers
			[self registerObservers];
			
			// attempt to start a session
            ApptentiveLogMonitorSession *session = [ApptentiveLogMonitorSessionIO readSessionFromPersistentStorage];
            if (session != nil) {
                ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Previous Apptentive Log Monitor session loaded from persistent storage: %@", session);
                [self startSession:session];
            } else {
                if ([self IsMobileConfigInstalled]) {
                    // Create session
                    ApptentiveLogMonitorSession *session = [[ApptentiveLogMonitorSession alloc] init];

                    // save session
                    [ApptentiveLogMonitorSessionIO writeSessionToPersistentStorage:session];

                    // start session
                    [self startSession:session];
                }
            }
		} @catch (NSException *e) {
			ApptentiveLogCrit(ApptentiveLogTagMonitor, @"Exception while starting log monitor session (%@)", e);
		}
	}];
}

+ (void)startSession:(nonnull ApptentiveLogMonitorSession *)session {
	ApptentiveAssertNil(_currentSession, @"Attempted to start a session while previous session is still active");
	_currentSession = session;
	[_currentSession start];
}

+ (BOOL)resumeSession {
	if (_currentSession != nil) {
		[_currentSession resume];
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Observers

+ (void)registerObservers {
	// Store raw manifest data each time the update is received
	NSString *manifestPath = [ApptentiveLogMonitorSession manifestFilePath];
	[[NSNotificationCenter defaultCenter] addObserverForName:ApptentiveManifestRawDataDidReceiveNotification
													  object:nil
													   queue:NSOperationQueue.currentQueue // dispatch on the same queue
												  usingBlock:^(NSNotification *_Nonnull note) {
													  NSData *data = note.userInfo[ApptentiveManifestRawDataKey];
													  ApptentiveAssertNotNil(data, @"Missing manifest data");
													  [data writeToFile:manifestPath atomically:YES];
												  }];
	
	// clean stored session when it's over
	[[NSNotificationCenter defaultCenter] addObserverForName:ApptentiveLogMonitorSessionDidStop
													  object:nil
													   queue:NSOperationQueue.currentQueue // dispatch on the same queue
												  usingBlock:^(NSNotification * _Nonnull note) {
													  ApptentiveAssertNotNil(_currentSession, @"Current session already stopped");
													  _currentSession = nil;
													  [ApptentiveLogMonitorSessionIO clearCurrentSession];
												  }];
}

#pragma mark -
#pragma mark Configuration Profile

+ (BOOL)IsMobileConfigInstalled {
    NSString* certPath = [[NSBundle bundleForClass:self] pathForResource:@"DebugLogging" ofType:@"cer"];
    if (certPath == nil) {
        return NO;
    }

    NSData* certData = [NSData dataWithContentsOfFile:certPath];
    if (certData == nil) {
        return NO;
    }

    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certData);
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust;

    OSStatus err = SecTrustCreateWithCertificates((__bridge CFArrayRef) [NSArray arrayWithObject:(__bridge id)cert], policy, &trust);

    SecTrustResultType trustResult = -1;

    err = SecTrustEvaluate(trust, &trustResult);

    CFRelease(trust);
    CFRelease(policy);
    CFRelease(cert);

    if(trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed) {
        return YES;
    } else {
        return NO;
    }
}

@end
