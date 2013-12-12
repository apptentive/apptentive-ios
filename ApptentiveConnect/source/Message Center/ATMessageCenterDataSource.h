//
//  ATMessageCenterDataSource.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol ATMessageCenterDataSourceDelegate;

@interface ATMessageCenterDataSource : NSObject
@property (nonatomic, readonly) NSFetchedResultsController *fetchedMessagesController;
@property (nonatomic, assign) NSObject<ATMessageCenterDataSourceDelegate> *delegate;

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)delegate;
- (void)start;
- (void)stop;
- (void)markAllMessagesAsRead;
- (void)createIntroMessageIfNecessary;
@end


@protocol ATMessageCenterDataSourceDelegate <NSObject, NSFetchedResultsControllerDelegate>

@end
