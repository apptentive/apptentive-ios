//
//  ATMessageTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAPIRequest.h"
#import "ATTask.h"
#import "ATCompoundMessage.h"


@interface ApptentiveMessageTask : ATTask <ApptentiveAPIRequestDelegate>

@property (strong, nonatomic) NSString *pendingMessageID;

@end
