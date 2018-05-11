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

+ (void)startSessionWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature queue:(nonnull ApptentiveDispatchQueue *)queue {
	if (baseURL == nil) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: base URL is nil.");
		return;
	}

	if (appKey.length == 0) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: app key is nil or empty.");
		return;
	}

	if (appSignature.length == 0) {
		ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to initialize log monitor: app signature is nil or empty.");
		return;
	}
	
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
			[self startSessionWithBaseURL:baseURL appKey:appKey signature:appSignature];
		} @catch (NSException *e) {
			ApptentiveLogCrit(ApptentiveLogTagMonitor, @"Exception while starting log monitor session (%@)", e);
		}
	}];
}

+ (void)startSessionWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature {
	ApptentiveLogMonitorSession *session = [ApptentiveLogMonitorSessionIO readSessionFromPersistentStorage];
	if (session != nil) {
		ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Previous Apptentive Log Monitor session loaded from persistent storage: %@", session);
		[self startSession:session];
	} else {
		// attempt to read access token from a clipboard
		NSString *accessToken = [self readAccessTokenFromClipboard];
		if (accessToken == nil) {
			ApptentiveLogVerbose(ApptentiveLogTagMonitor, @"No access token found in clipboard");
			return;
		}
		
		// clear pastboard text
		[[UIPasteboard generalPasteboard] setString:@""];
		
		// send token verification request
		[self verifyAccessToken:accessToken baseURL:baseURL appKey:appKey signature:appSignature completionHandler:^(BOOL sessionValid, NSError * _Nullable error) {
			if (!sessionValid) {
				ApptentiveLogVerbose(ApptentiveLogTagMonitor, @"Unable to start Apptentive Log Monitor: the access token was rejected on the server (%@)", accessToken);
				return;
			}
			
			ApptentiveLogMonitorSession *session = [ApptentiveLogMonitorSessionIO readSessionFromJWT:accessToken];
			if (session == nil) {
				ApptentiveLogVerbose(ApptentiveLogTagMonitor, @"Unable to start Apptentive Log Monitor: failed to parse the access token (%s)", accessToken);
				return;
			}
			
			ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Read log monitor configuration from clipboard: %@", session);
			
			// save session
			[ApptentiveLogMonitorSessionIO writeSessionToPersistentStorage:session];
			
			// start session
			[self startSession:session];
		}];
	}
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
#pragma mark Access Token

+ (nullable NSString *)readAccessTokenFromClipboard {
	NSString *text = [UIPasteboard generalPasteboard].string;

	// remove white spaces
	text = [text stringByReplacingOccurrencesOfString:@"\\s" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, text.length)];

	if (![text hasPrefix:DebugTextHeader]) {
		return nil;
	}
	
	// clear the token from the clipboard
	[UIPasteboard generalPasteboard].string = @"";

	return [text substringFromIndex:DebugTextHeader.length];
}

+ (void)verifyAccessToken:(NSString *)accessToken baseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature completionHandler:(void(^)(BOOL success, NSError *error))completionHandler {
	ApptentiveLogInfo(ApptentiveLogTagMonitor, @"Starting access token verification: %@", accessToken);

	NSData *body = [ApptentiveJSONSerialization dataWithJSONObject:@{ @"debug_token": accessToken } options:0 error:nil];

	NSDictionary *headers = @{
		@"X-API-Version": kApptentiveAPIVersionString,
		@"APPTENTIVE-KEY": appKey,
		@"APPTENTIVE-SIGNATURE": appSignature,
		@"Content-Type": @"application/json",
		@"Accept": @"application/json",
		@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (iOS)", kApptentiveVersionString]
	};

	NSURL *URL = [NSURL URLWithString:@"/debug_token/verify" relativeToURL:baseURL];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	for (NSString *key in headers) {
		[request setValue:headers[key] forHTTPHeaderField:key];
	}
	request.HTTPBody = body;
	request.HTTPMethod = @"POST";

	NSOperationQueue *delegateQueue = NSOperationQueue.currentQueue; // this is a hack: we dispatch the enclosing call on ApptentiveGCDDispatchQueue which is based on NSOperation queue
	ApptentiveAssertNotNil(delegateQueue, @"Delegate queue is nil");
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:delegateQueue];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (!data) {
			completionHandler(false, error);
			return;
		}
		
		NSError *jsonError;
		id object = [ApptentiveJSONSerialization JSONObjectWithData:data error:&jsonError];
		if (jsonError != nil) {
			ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to verify access token: returned json object is invalid (%@)", jsonError);
			completionHandler(false, jsonError);
			return;
		}
		
		if (![object isKindOfClass:[NSDictionary class]]) {
			ApptentiveLogError(ApptentiveLogTagMonitor, @"Unable to verify access token: unexpected JSON object (%@)", object);
			completionHandler(false, [ApptentiveUtilities errorWithCode:101 failureReason:@"Unexpected JSON object"]);
			return;
		}
		
		NSDictionary *json = (NSDictionary *)object;
		BOOL valid = [[json objectForKey:@"valid"] boolValue];
		
		completionHandler(valid, nil);
	}];
	[task resume];
}

@end
