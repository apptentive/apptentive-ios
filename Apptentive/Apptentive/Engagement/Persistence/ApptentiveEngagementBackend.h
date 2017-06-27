//
//  ApptentiveEngagementBackend.h
//  Apptentive
//
//  Created by Alex Lementuev on 6/26/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveInteraction;
@class ApptentiveConversation;
@class ApptentiveEngagementManifest;


@interface ApptentiveEngagementBackend : NSObject

@property (readonly, nonatomic) ApptentiveConversation *conversation;
@property (readonly, nonatomic) ApptentiveEngagementManifest *manifest;

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation manifest:(ApptentiveEngagementManifest *)manifest;

- (ApptentiveInteraction *)interactionForEvent:(NSString *)event;
- (ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations;

@end
