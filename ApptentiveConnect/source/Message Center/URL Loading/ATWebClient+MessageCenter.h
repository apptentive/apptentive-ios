//
//  ATWebClient+MessageCenter.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient.h"

#import "ATActivityFeed.h"
#import "ATDeviceInfo.h"
#import "ATMessage.h"
#import "ATPendingMessage.h"
#import "ATPerson.h"

@interface ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingActivityFeed:(ATActivityFeed *)activityFeed;
- (ATAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo;
- (ATAPIRequest *)requestForPostingMessage:(ATPendingMessage *)message;
- (ATAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATMessage *)message;
@end
