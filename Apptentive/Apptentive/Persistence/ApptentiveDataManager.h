//
//  ApptentiveDataManager.h
//  Apptentive
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveDataManager : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, nonatomic) BOOL didRemovePersistentStore;
@property (readonly, nonatomic) BOOL didFailToMigrateStore;
@property (readonly, nonatomic) BOOL didMigrateStore;

- (id)initWithModelName:(NSString *)modelName inBundle:(NSBundle *)bundle storagePath:(NSString *)path;

- (NSURL *)persistentStoreURL;
- (BOOL)setupAndVerify;

- (void)shutDownAndCleanUp;

@end

NS_ASSUME_NONNULL_END
