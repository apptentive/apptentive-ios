//
//  ATData.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/29/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATData.h"

#import "ATBackend.h"
#import "ATLog.h"

@implementation ATData
+ (NSManagedObject *)newEntityNamed:(NSString *)entityName {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	NSManagedObject *message = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	return message;
}

+ (NSArray *)findEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	NSFetchRequest *fetchType = [[NSFetchRequest alloc] initWithEntityName:entityName];
	fetchType.predicate = predicate;
	NSError *fetchError = nil;
	NSArray *fetchArray = [context executeFetchRequest:fetchType error:&fetchError];
	if (!fetchArray) {
		ATLogError(@"Error executing fetch request: %@", fetchError);
		fetchArray = nil;
	}
	[fetchType release], fetchType = nil;
	
	return fetchArray;
}

+ (void)removeEntitiesNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:entityName];
	fetchTypes.predicate = predicate;
	NSError *fetchError = nil;
	NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
	
	if (!fetchArray) {
		ATLogError(@"Error finding entities to remove: %@", fetchError);
	} else {
		for (NSManagedObject *fetchedObject in fetchArray) {
			[context deleteObject:fetchedObject];
		}
		[context save:nil];
	}
	
	[fetchTypes release], fetchTypes = nil;
}
@end
