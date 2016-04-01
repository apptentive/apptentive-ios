//
//  ATWebClient+MessageCenter.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveWebClient.h"

#import "ATConversation.h"
#import "ATDeviceInfo.h"
#import "ATCompoundMessage.h"
#import "ATPersonInfo.h"


@interface ApptentiveWebClient (MessageCenter)
- (ApptentiveAPIRequest *)requestForCreatingConversation:(ATConversation *)conversation;
- (ApptentiveAPIRequest *)requestForUpdatingConversation:(ATConversation *)conversation;

- (ApptentiveAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo;
- (ApptentiveAPIRequest *)requestForUpdatingPerson:(ATPersonInfo *)personInfo;
- (ApptentiveAPIRequest *)requestForPostingMessage:(ATCompoundMessage *)message;
- (ApptentiveAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATCompoundMessage *)message;
@end
