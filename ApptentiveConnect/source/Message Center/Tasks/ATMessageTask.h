//
//  ATMessageTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAPIRequest.h"
#import "ATTask.h"
#import "ATMessage.h"

@class ATPendingMessage;

@interface ATMessageTask : ATTask <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	NSString *pendingMessageID;
	ATMessage *message;
}
@property (nonatomic, retain) NSString *pendingMessageID;
@property (nonatomic, readonly) ATMessage *message;

@end
