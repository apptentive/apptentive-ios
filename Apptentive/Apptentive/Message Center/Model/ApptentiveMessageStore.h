//
//  ApptentiveMessageStore.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/3/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveMessageStore : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSString *lastMessageIdentifier;

@end
