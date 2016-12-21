//
//  ApptentiveMessageRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecordRequestOperation.h"
#import "ApptentiveMessage.h"

@interface ApptentiveMessageRequestOperation : ApptentiveRecordRequestOperation

@property (readonly, nonatomic) ApptentiveQueuedRequest *messageRequestInfo;

- (void)setMessagePendingState:(ATPendingMessageState)pendingState;

@end
