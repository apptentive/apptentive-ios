//
//  ATWebClient+MessageCenter.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient.h"

#import "ATConversation.h"
#import "ATDeviceInfo.h"
#import "ATMessage.h"
#import "ATPersonInfo.h"


@interface ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingConversation:(ATConversation *)conversation;
- (ATAPIRequest *)requestForUpdatingConversation:(ATConversation *)conversation;

- (ATAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo fromPreviousDevice:(ATDeviceInfo *)previousDevice;
- (ATAPIRequest *)requestForUpdatingPerson:(ATPersonInfo *)personInfo fromPreviousPerson:(ATPersonInfo *)previousPerson;
- (ATAPIRequest *)requestForPostingMessage:(ATMessage *)message;
- (ATAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATMessage *)message;
@end
