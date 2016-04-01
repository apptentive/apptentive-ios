//
//  ATRecordTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ApptentiveAPIRequest.h"

@class ATLegacyRecord;


@interface ATRecordTask : ATTask <ApptentiveAPIRequestDelegate>
@property (strong, nonatomic) ATLegacyRecord *record;

@end
