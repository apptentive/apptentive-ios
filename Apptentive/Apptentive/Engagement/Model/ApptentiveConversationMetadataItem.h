//
//  ApptentiveConversationMetadataItem.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveConversationMetadataItem : NSObject <NSSecureCoding>

- (nullable instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier directoryName:(NSString *)filename;

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *conversationIdentifier;
@property (strong, nonatomic) NSString *directoryName;
@property (strong, nonatomic, nullable) NSData *encryptionKey;
@property (strong, nonatomic, nullable) NSString *userId;
@property (strong, nonatomic, nullable) NSString *JWT;

@end

NS_ASSUME_NONNULL_END
