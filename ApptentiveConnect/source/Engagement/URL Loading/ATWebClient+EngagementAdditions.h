//
//  ATWebClient+EngagementAdditions.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient.h"

@interface ATWebClient (EngagementAdditions)
- (ATAPIRequest *)requestForGettingEngagementManifest;
@end

void ATWebClient_EngagementAdditions_Bootstrap();
