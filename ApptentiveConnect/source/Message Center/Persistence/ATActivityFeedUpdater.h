//
//  ATActivityFeedUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATAPIRequest.h"
#import "ATActivityFeed.h"

NSString *const ATCurrentActivityFeedPreferenceKey;

@protocol ATActivityFeedUpdaterDelegate;

@interface ATActivityFeedUpdater : NSObject <ATAPIRequestDelegate> {
@private
	NSObject<ATActivityFeedUpdaterDelegate> *delegate;
	ATAPIRequest *request;
}
@property (nonatomic, assign) NSObject<ATActivityFeedUpdaterDelegate> *delegate;
+ (BOOL)activityFeedExists;
+ (ATActivityFeed *)currentActivityFeed;

- (id)initWithDelegate:(NSObject<ATActivityFeedUpdaterDelegate> *)delegate;
- (void)createActivityFeed;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATActivityFeedUpdaterDelegate <NSObject>
- (void)activityFeed:(ATActivityFeedUpdater *)activityFeed createdFeed:(BOOL)success;
@end
