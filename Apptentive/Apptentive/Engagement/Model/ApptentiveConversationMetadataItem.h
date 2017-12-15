//
//  ApptentiveConversationMetadataItem.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveConversationMetadataItem : NSObject <NSSecureCoding>

- (nullable instancetype)initWithConversationLocalIdentifier:(NSString *)conversationLocalIdentifier conversationIdentifier:(nullable NSString *)conversationIdentifier directoryName:(NSString *)filename;

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic, nullable) NSString *conversationIdentifier;
@property (strong, nonatomic) NSString *directoryName;
@property (strong, nonatomic) NSString *conversationLocalIdentifier;
@property (strong, nonatomic, nullable) NSData *encryptionKey;
@property (strong, nonatomic, nullable) NSString *userId;
@property (strong, nonatomic, nullable) NSString *JWT;

@property (readonly, nonatomic, getter=isConsistent) BOOL consistent;

@end

NS_ASSUME_NONNULL_END
