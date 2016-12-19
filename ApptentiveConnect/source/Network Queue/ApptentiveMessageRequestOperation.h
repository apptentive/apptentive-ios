//
//  ApptentiveMessageRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecordRequestOperation.h"

@class ApptentiveMessage;

@interface ApptentiveMessageRequestOperation : ApptentiveRecordRequestOperation

@property (readonly, nonatomic) ApptentiveQueuedRequest *messageRequestInfo;

@end
