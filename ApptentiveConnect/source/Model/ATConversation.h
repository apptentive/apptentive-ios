//
//  ATConversation.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATUpdater.h"


@interface ATConversation : NSObject <NSCoding, ATUpdatable>

// deviceUUID is used for initial (create) request only. 
@property (readonly, nonatomic) NSUUID *deviceUUID;
@property (readonly, nonatomic) NSString *token;
@property (readonly, nonatomic) NSString *personID;
@property (readonly, nonatomic) NSString *deviceID;
@property (strong, nonatomic) NSString *lastRetrievedMessageID;

- (NSDictionary *)initialDictionaryRepresentation;

@end
