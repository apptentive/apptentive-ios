//
//  ApptentiveMessageStore.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/3/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageStore : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSMutableArray *messages;
@property (nullable, strong, nonatomic) NSString *lastMessageIdentifier;

@end

NS_ASSUME_NONNULL_END
