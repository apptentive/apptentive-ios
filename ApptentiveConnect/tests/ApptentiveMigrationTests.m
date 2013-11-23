//
//  ApptentiveMigrationTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMigrationTests.h"
#import "ATDataManager.h"

@implementation ApptentiveMigrationTests
- (ATDataManager *)dataManagerWithStoreName:(NSString *)name {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *storeURL = [bundle URLForResource:name withExtension:@"sqlite"];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	ATDataManager *dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:path];

	NSError *error = nil;
	[fileManager removeItemAtURL:[dataManager persistentStoreURL] error:nil];
	if (![fileManager copyItemAtURL:storeURL toURL:[dataManager persistentStoreURL] error:&error]) {
		STFail(@"Unable to copy item: %@", error);
		[dataManager release];
		return nil;
	}
	return dataManager;
}

- (void)testV1Upgrade {
	// For example, we will do the following with a copy of an old data model.
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv1"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	STAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	STAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	STAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	[dataManager release];
}

- (void)testV2Upgrade {
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv2"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	STAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	STAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	STAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	[dataManager release];
}

- (void)testCurrentDatabaseVersion {
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv3"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	STAssertFalse([dataManager didMigrateStore], @"Should not have had to migrate the datastore.");
	STAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	STAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	[dataManager release];
}

- (ATDataManager *)dataManagerByCopyingSQLFilesInDirectory:(NSString *)directoryName {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSArray *files = @[@"ATDataModel.sqlite", @"ATDataModel.sqlite-shm", @"ATDataModel.sqlite-wal"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	for (NSString *filename in files) {
		NSString *name = [filename stringByDeletingPathExtension];
		NSString *extension = [filename pathExtension];
		
		NSString *source = [bundle pathForResource:name ofType:extension inDirectory:directoryName];
		NSString *destination = [path stringByAppendingPathComponent:filename];
		NSError *error = nil;
		
		[fileManager removeItemAtPath:destination error:nil];
		if (![fileManager fileExistsAtPath:source isDirectory:NULL]) {
			STFail(@"Unable to find file: %@", source);
		}
		if (![fileManager copyItemAtPath:source toPath:destination error:&error]) {
			STFail(@"Unable to copy item: %@", error);
			return nil;
		}
	}
	
	ATDataManager *dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:path];
	return dataManager;
}

- (void)testV2WALDatabase {
	// A valid v2 database, albeit in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v2WALDatabase"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Should be able to use existing WAL database.");
	STAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	STAssertFalse([dataManager didFailToMigrateStore], @"Should not have failed to migrate the persistent store.");
	STAssertFalse([dataManager didRemovePersistentStore], @"Should not have had to delete the persistent store.");
	[dataManager release];
}

- (void)testV3WALDatabase {
	// A valid v3 database, albeit in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v3WALDatabase"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Should be able to use existing WAL database.");
	STAssertFalse([dataManager didMigrateStore], @"Should not have had to migrate the datastore.");
	STAssertFalse([dataManager didFailToMigrateStore], @"Should not have failed to migrate the persistent store.");
	STAssertFalse([dataManager didRemovePersistentStore], @"Should not have had to delete the persistent store.");
	[dataManager release];
}

- (void)testCorruptV2DatabaseRecovery {
	// A corrupt v3 database in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v2CorruptDatabase"];
	
	STAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	STAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil after fixing it.");
	STAssertTrue([dataManager didRemovePersistentStore], @"Should have had to delete the persistent store.");
	[dataManager release];
}
@end
