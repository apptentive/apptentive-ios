//
//  ATMessageDisplayType.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessageDisplayType.h"
#import "ATBackend.h"
#import "ATMessage.h"


@implementation ATMessageDisplayType
static ATMessageDisplayType *messageCenterTypeSingleton = nil;
static ATMessageDisplayType *modalTypeSingleton = nil;


@dynamic displayType;
@dynamic messages;

+ (void)setupSingletons {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATMessageDisplayType"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(displayType == %d) || (displayType == %d)", ATMessageDisplayTypeTypeMessageCenter, ATMessageDisplayTypeTypeModal];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		[fetchTypes release], fetchTypes = nil;
		
		if (!fetchArray) {
			[NSException raise:NSGenericException format:@"%@", [fetchError description]];
		} else {
			for (NSManagedObject *fetchedObject in fetchArray) {
				ATMessageDisplayType *dt = (ATMessageDisplayType *)fetchedObject;
				ATMessageDisplayTypeType displayType = (ATMessageDisplayTypeType)[[dt displayType] intValue];
				if (displayType == ATMessageDisplayTypeTypeModal) {
					[modalTypeSingleton release], modalTypeSingleton = nil;
					modalTypeSingleton = [dt retain];
				} else if (displayType == ATMessageDisplayTypeTypeMessageCenter) {
					[messageCenterTypeSingleton release], messageCenterTypeSingleton = nil;
					messageCenterTypeSingleton = [dt retain];
				}
			}
		}
		
		if (!messageCenterTypeSingleton) {
			messageCenterTypeSingleton = [[ATMessageDisplayType alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessageDisplayType" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			messageCenterTypeSingleton.displayType = [NSNumber numberWithInt:ATMessageDisplayTypeTypeMessageCenter];
			[context save:nil];
		}
		if (!modalTypeSingleton) {
			modalTypeSingleton = [[ATMessageDisplayType alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessageDisplayType" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			modalTypeSingleton.displayType = [NSNumber numberWithInt:ATMessageDisplayTypeTypeModal];
			[context save:nil];
		}
	}
}

+ (ATMessageDisplayType *)messageCenterType {
	@synchronized(self) {
		if (messageCenterTypeSingleton == nil) {
			[self setupSingletons];
		}
		return messageCenterTypeSingleton;
	}
}

+ (ATMessageDisplayType *)modalType {
	@synchronized(self) {
		if (modalTypeSingleton == nil) {
			[self setupSingletons];
		}
		return modalTypeSingleton;
	}
}
@end
