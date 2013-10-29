//
//  ATMessageDisplayType.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
	ATMessageDisplayTypeTypeUnknown,
	ATMessageDisplayTypeTypeModal,
	ATMessageDisplayTypeTypeMessageCenter,
} ATMessageDisplayTypeType;

@class ATAbstractMessage;

@interface ATMessageDisplayType : NSManagedObject

@property (nonatomic, retain) NSNumber *displayType;
@property (nonatomic, retain) NSSet *messages;

+ (void)setupSingletons;
+ (ATMessageDisplayType *)messageCenterType;
+ (ATMessageDisplayType *)modalType;
@end

@interface ATMessageDisplayType (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(ATAbstractMessage *)value;
- (void)removeMessagesObject:(ATAbstractMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
