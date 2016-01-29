//
//  ATConversationUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATDiffingUpdater.h"

@class ATConversation;

@interface ATConversationUpdater : ATDiffingUpdater

@property (readonly, nonatomic) ATConversation *currentConversation;

- (void)create;
- (BOOL)needsCreation;

@property (readonly, nonatomic, getter=isCreating) BOOL creating;

@end
