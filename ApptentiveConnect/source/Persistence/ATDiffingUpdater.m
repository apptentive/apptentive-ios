//
//  ATDiffingUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATDiffingUpdater.h"

@interface ATDiffingUpdater ()

@property (strong, nonatomic) NSString *currentVersionPath;
@property (strong, nonatomic) NSString *previousVersionPath;

@end

@implementation ATDiffingUpdater

@synthesize currentVersion = _currentVersion;
@synthesize previousVersion = _previousVersion;

#pragma  mark - Methods to override

+ (Class <ATUpdatable>)updatableClass {
	return nil;
}


- (id<ATUpdatable>)previousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	return nil;
}

- (void)removePreviousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	// Subclasses should clear out user defaults keys after migration
}

- (id<ATUpdatable>)emptyCurrentVersion	{
	return nil;
}

- (ATAPIRequest *)requestForUpdating {
	return nil;
}

#pragma mark -

- (NSString *)currentVersionPath {
	return [self.storagePath stringByAppendingPathExtension:@".current"];
}

- (NSString *)previousVersionPath {
	return [self.storagePath stringByAppendingPathExtension:@".previous"];
}

- (BOOL)needsUpdate {
	BOOL previousVersionIsStale = ![self.previousVersion.dictionaryRepresentation isEqualToDictionary:self.currentVersion.dictionaryRepresentation];
	BOOL updateVersionIsStale = ![self.updateVersion.dictionaryRepresentation isEqualToDictionary:self.currentVersion.dictionaryRepresentation];

	if (self.request) {
		// Currently updating. We need to update if version being sent to server is stale.
		return updateVersionIsStale;
	} else {
		// Not currently updating. We need to update if last sent version is stale.
		return previousVersionIsStale;
	}
}

- (NSDictionary *)lastSentVersion {
	return [NSDictionary dictionaryWithContentsOfFile:self.storagePath];
}

- (id<ATUpdatable>)previousVersion {
	if (_previousVersion == nil) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.previousVersionPath]) {
			_previousVersion = [NSKeyedUnarchiver unarchiveObjectWithFile:self.previousVersionPath];
		} else if ([self previousVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]]) {
			_previousVersion = [self previousVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]];
			[self archivePreviousVersion];
			[self removePreviousVersionFromUserDefaults:[NSUserDefaults standardUserDefaults]];
		} else {
			_previousVersion = nil;
		}
	}

	return _currentVersion;
}

- (void)update {
	self.updateVersion = self.currentVersion;
	[super update];
}

- (void)didUpdateWithRequest:(ATAPIRequest *)request {
	_previousVersion = self.updateVersion;
	self.updateVersion = nil;

	[self archivePreviousVersion];
}

- (void)archivePreviousVersion {
	[NSKeyedArchiver archiveRootObject:_previousVersion toFile:self.previousVersionPath];
}

@end
