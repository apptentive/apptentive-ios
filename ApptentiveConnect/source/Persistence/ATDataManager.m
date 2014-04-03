//
//  ATDataManager.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATDataManager.h"

// Used to indicate a database upgrade or check was in progress and didn't complete.
NSString *const ATDataManagerUpgradeCanaryFilename = @"ATDataManagerUpgradeCanary";

typedef enum {
	ATMigrationMergedModelErrorCode = -100,
	ATMigrationNoModelsFoundErrorCode = -101,
	ATMigrationNoMatchingModelFoundErrorCode = -102,
} ATMigrationErrorCode;

@interface ATDataManager (Migration)
- (BOOL)isMigrationNecessary:(NSPersistentStoreCoordinator *)psc;
- (BOOL)migrateStoreError:(NSError **)error;
- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL ofType:(NSString *)type toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error;
- (BOOL)removeSQLiteSidecarsForPath:(NSString *)sourcePath;
@end

@implementation ATDataManager {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectModel *managedObjectModel;
	
	NSString *modelName;
	NSBundle *bundle;
	NSString *supportDirectoryPath;
}
@synthesize didRemovePersistentStore, didFailToMigrateStore, didMigrateStore;

- (id)initWithModelName:(NSString *)aModelName inBundle:(NSBundle *)aBundle storagePath:(NSString *)path {
	if ((self = [super init])) {
		modelName = [aModelName retain];
		bundle = [aBundle retain];
		supportDirectoryPath = [path retain];
		
		// Check the canary.
		if ([self canaryFileExists]) {
			[self removePersistentStore];
			[self removeCanaryFile];
		}
	}
	return self;
}

- (void)dealloc {
	[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
	[managedObjectContext release], managedObjectContext = nil;
	[managedObjectModel release], managedObjectModel = nil;
	[modelName release], modelName = nil;
	[bundle release], bundle = nil;
	[supportDirectoryPath release], supportDirectoryPath = nil;
	[super dealloc];
}

#pragma mark Properties
- (NSManagedObjectContext *)managedObjectContext {
	@synchronized(self) {
		if (managedObjectContext != nil) {
			return managedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [bundle URLForResource:modelName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

- (BOOL)setupAndVerify {
	// Set the canary.
	if (![self createCanaryFile]) {
		return NO;
	}
	
	if (![self persistentStoreCoordinator]) {
		// This is almost certainly something bad.
		return NO;
	}
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	@try {
		// Due to a migration error from v2 to v3, these items may not have customData fields.
		[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:moc]];
		[request setFetchBatchSize:20];
		NSArray *results = [moc executeFetchRequest:request error:nil];
		for (NSManagedObject *c in results) {
			__unused NSObject *d = [c valueForKey:@"customData"];
			break;
		}
	}
	@catch (NSException *exception) {
		ATLogError(@"Caught exception attempting to test classes: %@", exception);
		[managedObjectContext release], managedObjectContext = nil;
		[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
		ATLogError(@"Removing persistent store and starting over.");
		[self removePersistentStore];
	}
	@finally {
		[request release], request = nil;
	}
	
	if (![self persistentStoreCoordinator]) {
		return NO;
	}
	// Seems to have gone well, so remove canary.
	if (![self removeCanaryFile]) {
		return NO;
	}
	return YES;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	@synchronized(self) {
		if (persistentStoreCoordinator != nil) {
			return persistentStoreCoordinator;
		}
		
		NSURL *storeURL = [self persistentStoreURL];
		
		NSError *error = nil;
		@try {
			persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		}
		@catch (NSException *exception) {
			ATLogError(@"Unable to setup persistent store: %@", exception);
			return nil;
		}
		BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]];
		
		if (storeExists && [self isMigrationNecessary:persistentStoreCoordinator]) {
			if (![self migrateStoreError:&error]) {
				ATLogError(@"Failed to migrate store. Need to start over from scratch: %@", error);
				didFailToMigrateStore = YES;
				[self removePersistentStore];
			} else {
				didMigrateStore = YES;
			}
		}
		
		// By default, the value of NSPersistentStoreFileProtectionKey is:
		// iOS 4 and earlier: NSFileProtectionNone
		// iOS 5 and later: NSFileProtectionCompleteUntilFirstUserAuthentication
		// So, there's no need to set these explicitly for our purposes.
		NSDictionary *options = @{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}};
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
			ATLogError(@"Unable to create new persistent store: %@", error);
			[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
			return nil;
		}
	}
	return persistentStoreCoordinator;
}

#pragma mark -
- (NSURL *)persistentStoreURL {
	NSString *sqliteFilename = [modelName stringByAppendingPathExtension:@"sqlite"];
	return [[NSURL fileURLWithPath:supportDirectoryPath] URLByAppendingPathComponent:sqliteFilename];
}

- (void)removePersistentStore {
	NSURL *storeURL = [self persistentStoreURL];
	NSString *sourcePath = [storeURL path];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:sourcePath]) {
		NSError *error = nil;
		if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
			ATLogError(@"Failed to delete the store: %@", error);
		}
	}
	[self removeSQLiteSidecarsForPath:sourcePath];
	didRemovePersistentStore = YES;
}

#pragma mark - Upgrade Canary
- (NSString  *)canaryFilePath {
	return [supportDirectoryPath stringByAppendingPathComponent:ATDataManagerUpgradeCanaryFilename];
}

- (BOOL)canaryFileExists {
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self canaryFilePath] isDirectory:&isDirectory] && !isDirectory) {
		return YES;
	}
	return NO;
}

- (BOOL)createCanaryFile {
	NSDictionary *data = @{@"upgrading":@YES};
	return [data writeToFile:[self canaryFilePath] atomically:YES];
}

- (BOOL)removeCanaryFile {
	NSError *error = nil;
	if ([[NSFileManager defaultManager] removeItemAtPath:[self canaryFilePath] error:&error]) {
		return YES;
	}
	ATLogError(@"Error removing upgrade canary: %@", error);
	return NO;
}
@end


@implementation ATDataManager (Migration)

- (BOOL)isMigrationNecessary:(NSPersistentStoreCoordinator *)psc {
	NSString *sourceStoreType = NSSQLiteStoreType;
	NSURL *sourceStoreURL = [self persistentStoreURL];
	
	NSError *error = nil;
	
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:sourceStoreType URL:sourceStoreURL error:&error];
	if (sourceMetadata == nil) {
		return YES;
	}
	NSManagedObjectModel *destinationModel = [psc managedObjectModel];
	BOOL isCompatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
	return !isCompatible;
}

- (BOOL)migrateStoreError:(NSError **)error {
	NSString *sourceStoreType = NSSQLiteStoreType;
	NSURL *sourceStoreURL = [self persistentStoreURL];
	return [self progressivelyMigrateURL:sourceStoreURL ofType:sourceStoreType toModel:[self managedObjectModel] error:error];
}

- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL ofType:(NSString *)type toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error {
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type URL:sourceStoreURL error:error];
	if (sourceMetadata == nil) {
		return NO;
	}
	if ([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		if (error) {
			*error = nil;
		}
		return YES;
	}
	
	// Find source model.
	NSArray *bundlesForSourceModel = @[bundle];
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundlesForSourceModel forStoreMetadata:sourceMetadata];
	if (sourceModel == nil) {
		ATLogError(@"Failed to find source model.");
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationMergedModelErrorCode userInfo:@{NSLocalizedDescriptionKey: @"Failed to find source model for migration"}];
		}
		return NO;
	}
	
	NSMutableArray *modelPaths = [NSMutableArray array];
	NSArray *momdPaths = [bundle pathsForResourcesOfType:@"momd" inDirectory:nil];
	
	for (NSString *momdPath in momdPaths) {
		NSString *resourceSubpath = [momdPath lastPathComponent];
		NSArray *array = [bundle pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
		[modelPaths addObjectsFromArray:array];
	}
	
	NSArray *otherModels = [bundle pathsForResourcesOfType:@"mom" inDirectory:nil];
	[modelPaths addObjectsFromArray:otherModels];
	
	if (!modelPaths || ![modelPaths count]) {
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationNoModelsFoundErrorCode userInfo:@{NSLocalizedDescriptionKey: @"No models found in bundle"}];
		}
		return NO;
	}
	
	// Find matching destination model.
	NSMappingModel *mappingModel = nil;
	NSManagedObjectModel *targetModel = nil;
	NSString *modelPath = nil;
	NSArray *bundlesForTargetModel = @[bundle];
	for (modelPath in modelPaths) {
		targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
		mappingModel = [NSMappingModel mappingModelFromBundles:bundlesForTargetModel forSourceModel:sourceModel destinationModel:targetModel];
		if (mappingModel) {
			break;
		}
		[targetModel release], targetModel = nil;
	}
	[targetModel autorelease];
	
	if (!mappingModel) {
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationNoMatchingModelFoundErrorCode userInfo:@{NSLocalizedDescriptionKey: @"No matching migration found in bundle"}];
		}
		return NO;
	}
	
	// Mapping model and destination model found. Migrate them.
	NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:targetModel];
	NSString *localModelName = [[modelPath lastPathComponent] stringByDeletingPathExtension];
	NSString *storeExtension = [[sourceStoreURL path] pathExtension];
	NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
	storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, localModelName, storeExtension];
	NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
	
	NSDictionary *options = @{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}};
	if (![manager migrateStoreFromURL:sourceStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationStoreURL destinationType:type destinationOptions:options error:error]) {
		[manager release], manager = nil;
		return NO;
	}
	[manager release], manager = nil;
	
	// Move files around.
	NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
	guid = [guid stringByAppendingPathExtension:localModelName];
	guid = [guid stringByAppendingPathExtension:storeExtension];
	NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
	NSString *backupPath = [appSupportPath stringByAppendingPathComponent:guid];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager moveItemAtPath:[sourceStoreURL path] toPath:backupPath error:error]) {
		ATLogError(@"Unable to backup source store path.");
		return NO;
	}
	
	if (![fileManager moveItemAtPath:storePath toPath:[sourceStoreURL path] error:error]) {
		[fileManager moveItemAtPath:backupPath toPath:[sourceStoreURL path] error:nil];
		ATLogError(@"Unable to move new store into place.");
		return NO;
	} else {
		// Kill any remaining -wal or -shm files. Kill them with fire.
		// See: http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
		// Also: http://stackoverflow.com/questions/17487306/ios-coredata-are-there-any-disadvantages-to-enabling-sqlite-wal-write-ahead
		NSString *sourcePath = [sourceStoreURL path];
		[self removeSQLiteSidecarsForPath:sourcePath];
	}
	
	return [self progressivelyMigrateURL:sourceStoreURL ofType:type toModel:finalModel error:error];
}

- (BOOL)removeSQLiteSidecarsForPath:(NSString *)sourcePath {
	NSArray *extensions = @[@"-shm", @"-wal"];
	BOOL success = YES;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSString *ext in extensions) {
		NSString *obsoletePath = [sourcePath stringByAppendingString:ext];
		BOOL isDir = NO;
		NSError *localError = nil;
		if ([fileManager fileExistsAtPath:obsoletePath isDirectory:&isDir] && !isDir) {
			if (![fileManager removeItemAtPath:obsoletePath error:&localError]) {
				ATLogError(@"Unable to remove obsolete WAL file %@ with error: %@", obsoletePath, localError);
				success = NO;
			}
		}
	}
	return success;
}
@end
