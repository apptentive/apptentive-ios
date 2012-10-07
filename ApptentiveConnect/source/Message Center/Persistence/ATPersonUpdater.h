//
//  ATPersonUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATAPIRequest.h"
#import "ATPerson.h"

NSString *const ATCurrentPersonPreferenceKey;

@protocol ATPersonUpdaterDelegate;

@interface ATPersonUpdater : NSObject <ATAPIRequestDelegate> {
@private
	NSObject<ATPersonUpdaterDelegate> *delegate;
	ATAPIRequest *request;
}
@property (nonatomic, assign) NSObject<ATPersonUpdaterDelegate> *delegate;
+ (BOOL)personExists;
+ (ATPerson *)currentPerson;

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)delegate;
- (void)createPerson;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATPersonUpdaterDelegate <NSObject>
- (void)personUpdater:(ATPersonUpdater *)personUpdater didFinish:(BOOL)success;
@end

