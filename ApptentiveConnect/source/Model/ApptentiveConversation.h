//
//  ApptentiveConversation.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveJSONModel.h"


@interface ApptentiveConversation : NSObject <NSCoding, ApptentiveJSONModel>
@property (readonly, nonatomic) NSString *token;
@property (readonly, nonatomic) NSString *personID;
@property (readonly, nonatomic) NSString *deviceID;

- (NSDictionary *)apiUpdateJSON;
@end
