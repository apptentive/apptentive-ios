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


@interface ATMessageTask : ATTask <ATAPIRequestDelegate>

@property (nonatomic, strong) NSString *pendingMessageID;

@end
