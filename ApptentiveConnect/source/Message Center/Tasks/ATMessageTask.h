//
//  ATMessageTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAPIRequest.h"
#import "ATTask.h"
#import "ATAbstractMessage.h"

@protocol ATMessageTaskProgressDelegate;

@interface ATMessageTask : ATTask <ATAPIRequestDelegate>

@property (nonatomic, strong) NSString *pendingMessageID;
@property (weak, nonatomic) id<ATMessageTaskProgressDelegate> progressDelegate;

@end

@protocol ATMessageTaskProgressDelegate <NSObject>
@required
- (void)messageTaskDidBegin:(ATMessageTask *)messageTask;
- (void)messageTask:(ATMessageTask *)messageTask didProgress:(float)progress;
- (void)messageTaskDidFinish:(ATMessageTask *)messageTask;
@end
