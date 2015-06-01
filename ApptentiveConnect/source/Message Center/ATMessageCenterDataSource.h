//
//  ATMessageCenterDataSource.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, ATMessageCenterMessageType) {
	ATMessageCenterMessageTypeMessage,
	ATMessageCenterMessageTypeReply
};

@protocol ATMessageCenterDataSourceDelegate;

@interface ATMessageCenterDataSource : NSObject
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedMessagesController;
@property (nonatomic, weak) NSObject<ATMessageCenterDataSourceDelegate> *delegate;

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)delegate;
- (void)start;
- (void)stop;

- (NSInteger)numberOfMessageGroups;
- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex;
- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)dateOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath;
- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, readonly) BOOL lastMessageIsReply;

@end

@protocol ATMessageCenterDataSourceDelegate <NSObject, NSFetchedResultsControllerDelegate>

@end
