//
//  ApptentiveMessageRequestOperation.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequestOperation.h"
#import "ApptentiveLegacyMessage.h"


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

/**
 Shadows the `requestInfo` property with the proper type casting.
 */
@property (readonly, nonatomic) ApptentiveSerialRequest *messageRequestInfo;

/**
 Sets the pending state of the `ATMessage` entity associated with the request.

 @param pendingState The `ATPendingMessageState` value with which to update the
 message.
 */
- (void)setMessagePendingState:(ATPendingMessageState)pendingState;

@end
