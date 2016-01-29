//
//  ATUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATUpdater.h"

@implementation ATUpdater

@synthesize currentVersion = _currentVersion;

#pragma  mark - Methods to override

+ (Class <ATUpdatable>)updatableClass {
	return nil;
}

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	return nil;
}

- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
}

- (id<ATUpdatable>)emptyCurrentVersion	{
	return nil;
}

- (ATAPIRequest *)requestForUpdating {
	return nil;
}

- (BOOL)needsUpdate {
	return NO;
}

#pragma mark -

- (NSString *)currentVersionPath {
	return [self.storagePath stringByAppendingPathExtension:@".current"];
}

- (instancetype)initWithStoragePath:(NSString *)storagePath {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
	}

	return self;
}

- (id<ATUpdatable>)currentVersion {
	if (_currentVersion == nil) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.currentVersionPath]) {
			_currentVersion = [NSKeyedUnarchiver unarchiveObjectWithFile:self.currentVersionPath];
		} else if ([self currentVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]]) {
			_currentVersion = [self currentVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]];
			[self archiveCurrentVersion];
			[self removeCurrentVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]];
		} else {
			_currentVersion = [self emptyCurrentVersion];
		}
	}

	return _currentVersion;
}

- (void)update {
	[self cancel];
	self.request = [self requestForUpdating];
	self.request.delegate = self;
	[self.request start];
}

- (BOOL)isUpdating {
	return self.request != nil;
}

- (void)cancel {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
	}
}

- (void)didUpdateWithRequest:(ATAPIRequest *)request {
	[self archiveCurrentVersion];
	// Subclasses will perform post-success processing here.
}

- (void)archiveCurrentVersion	 {
	[NSKeyedArchiver archiveRootObject:_currentVersion toFile:self.currentVersionPath];
}

#pragma mark - ATAPIRequestDelegate

- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result {
	if ([result isKindOfClass:[NSDictionary class]]) {
		id<ATUpdatable> updatable = [[[self class] updatableClass] newInstanceFromDictionary:(NSDictionary *)result];
		if (updatable) {
			_currentVersion = updatable;
			[self didUpdateWithRequest:request];
			[self.delegate updater:self didFinish:YES];
			self.request = nil;
		}
	} else {
		ATLogError(@"Updater response object is not dictionary");
	}
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)request {
	ATLogInfo(@"Request failed: %@, %@", request.errorTitle, request.errorMessage);

	[self.delegate updater:self didFinish:NO];
	self.request = nil;
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)request {
}

@end
