//
//  ApptentiveConversationMetadataItem.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ApptentiveConversationState) {
	ApptentiveConversationStateNone = 0,
	ApptentiveConversationStateAnonymousPending,
	ApptentiveConversationStateAnonymous,
	ApptentiveConversationStateLoggedIn,
	ApptentiveConversationStateLoggedOut
};

@interface ApptentiveConversationMetadataItem : NSObject <NSSecureCoding>

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier filename:(NSString *)filename;

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *conversationIdentifier;
@property (strong, nonatomic) NSString *fileName;

@end
