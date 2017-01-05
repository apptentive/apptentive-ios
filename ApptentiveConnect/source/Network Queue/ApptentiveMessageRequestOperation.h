//
//  ApptentiveMessageRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequestOperation.h"
#import "ApptentiveMessage.h"

@interface ApptentiveMessageRequestOperation : ApptentiveSerialRequestOperation

@property (readonly, nonatomic) ApptentiveSerialRequest *messageRequestInfo;

- (void)setMessagePendingState:(ATPendingMessageState)pendingState;

@end
