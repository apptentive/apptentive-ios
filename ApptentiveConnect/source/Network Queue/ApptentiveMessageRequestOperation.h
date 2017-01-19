//
//  ApptentiveMessageRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequestOperation.h"
#import "ApptentiveMessage.h"


/**
 An `ApptentiveMessageRequestOperation` is a subclass of
 `ApptentiveSerialRequestOperation` that manages updating the pending state
 of a Message Center message based on the success or failure of the most recent
 network request in the serial queue to which it has been added.

 It also manages the construction of multipart requests that allow sending
 attachments alongside message text (although this is used for messages without
 attachments as well).
 */
@interface ApptentiveMessageRequestOperation : ApptentiveSerialRequestOperation

@property (readonly, nonatomic) ApptentiveSerialRequest *messageRequestInfo;

- (void)setMessagePendingState:(ATPendingMessageState)pendingState;

@end
