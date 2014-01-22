//
//  ApptentiveMigrationTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMigrationTests.h"
#import "ATDataManager.h"
#import "ATAbstractMessage.h"
#import "ATTextMessage.h"

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
		XCTFail(@"Unable to copy item: %@", error);
		[dataManager release];
		return nil;
	}
	return dataManager;
}

- (void)testCurrentDatabaseVersion {
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv4"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	XCTAssertFalse([dataManager didMigrateStore], @"Should not have had to migrate the datastore.");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	
	// Test that default value of hidden is NO for existing objects.
	NSManagedObjectContext *moc = [dataManager managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	@try {
		[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:moc]];
		[request setFetchBatchSize:20];
		NSArray *results = [moc executeFetchRequest:request error:nil];
		XCTAssertTrue([results count] > 0, @"No messages found after database migration.");
		for (NSManagedObject *c in results) {
			ATAbstractMessage *message = (ATAbstractMessage *)c;
			XCTAssertNotNil(message.hidden, @"Messages should be visible by default after migration.");
			XCTAssertFalse([(NSNumber *)message.hidden boolValue], @"Messages should be visible by default after migration.");
		}
	}
	@catch (NSException *exception) {
		XCTFail(@"Unable to perform query: %@", exception);
	}
	@finally {
		[request release], request = nil;
	}
	[dataManager release];
}

- (void)testV1Upgrade {
	// For example, we will do the following with a copy of an old data model.
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv1"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	XCTAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	[dataManager release];
}

- (void)testV2Upgrade {
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv2"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	XCTAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
	[dataManager release];
}

- (void)testV3Upgrade {
	ATDataManager *dataManager = [self dataManagerWithStoreName:@"ATDataModelv3"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
	XCTAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Failed to migrate the datastore.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Shouldn't have had to delete datastore.");
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
			XCTFail(@"Unable to find file: %@", source);
		}
		if (![fileManager copyItemAtPath:source toPath:destination error:&error]) {
			XCTFail(@"Unable to copy item: %@", error);
			return nil;
		}
	}
	
	ATDataManager *dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:path];
	return dataManager;
}

- (void)testV2WALDatabase {
	// A valid v2 database, albeit in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v2WALDatabase"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Should be able to use existing WAL database.");
	XCTAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore.");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Should not have failed to migrate the persistent store.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Should not have had to delete the persistent store.");
	[dataManager release];
}

- (void)testV3WALDatabase {
	// A valid v3 database, albeit in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v3WALDatabase"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Should be able to use existing WAL database.");
	XCTAssertTrue([dataManager didMigrateStore], @"Should have had to migrate the datastore (from v3 to a later version).");
	XCTAssertFalse([dataManager didFailToMigrateStore], @"Should not have failed to migrate the persistent store.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Should not have had to delete the persistent store.");
	[dataManager release];
}

- (void)testCorruptV2DatabaseRecovery {
	// A corrupt v3 database in WAL format.
	ATDataManager *dataManager = [self dataManagerByCopyingSQLFilesInDirectory:@"v2CorruptDatabase"];
	
	XCTAssertTrue([dataManager setupAndVerify], @"Should be able to setup database.");
	XCTAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil after fixing it.");
	XCTAssertFalse([dataManager didRemovePersistentStore], @"Should not have had to delete the persistent store, now that we have v4.");
	[dataManager release];
}
@end
