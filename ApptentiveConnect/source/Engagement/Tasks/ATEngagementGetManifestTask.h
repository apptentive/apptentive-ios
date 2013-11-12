//
//  ATEngagementGetManifestTask.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ATAPIRequest.h"

@interface ATEngagementGetManifestTask : ATTask <ATAPIRequestDelegate> {
@private
	ATAPIRequest *checkManifestRequest;
}

@end
