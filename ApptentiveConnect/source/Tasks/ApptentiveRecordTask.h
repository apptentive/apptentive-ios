//
//  ATRecordTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTask.h"
#import "ApptentiveAPIRequest.h"

@class ApptentiveLegacyRecord;


@interface ApptentiveRecordTask : ApptentiveTask <ApptentiveAPIRequestDelegate>
@property (strong, nonatomic) ApptentiveLegacyRecord *record;

@end
