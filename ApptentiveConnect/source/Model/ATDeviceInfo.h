//
//  ATDeviceInfo.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATLegacyRecord.h"

@interface ATDeviceInfo : NSObject {
@private
	ATLegacyRecord *record;
}

- (NSDictionary *)apiJSON;
@end
