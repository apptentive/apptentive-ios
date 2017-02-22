//
//  ApptentiveConversationMetadata.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveConversationMetadata : NSObject <NSSecureCoding>

@property (strong, nonatomic) NSMutableArray *items;

@end
