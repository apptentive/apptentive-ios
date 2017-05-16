//
//  ApptentiveConversationMetadataItem.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveConversation.h"


@interface ApptentiveConversationMetadataItem : NSObject <NSSecureCoding>

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier directoryName:(NSString *)filename;

@property (strong, nonatomic) NSData *encryptionKey;
@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *conversationIdentifier;
@property (strong, nonatomic) NSString *directoryName;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *JWT;

@end
