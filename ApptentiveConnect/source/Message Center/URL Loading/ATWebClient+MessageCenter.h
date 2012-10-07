//
//  ATWebClient+MessageCenter.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient.h"

#import "ATDeviceInfo.h"
#import "ATPendingMessage.h"
#import "ATPerson.h"

@interface ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingPerson:(ATPerson *)person;
- (ATAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo;
- (ATAPIRequest *)requestForPostingMessage:(ATPendingMessage *)message;
@end
