//
//  ATConversation.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATJSONModel.h"

@interface ATConversation : NSObject <NSCoding, ATJSONModel> {
@private
	NSString *token;
	NSString *personID;
	NSString *deviceID;
}
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *personID;
@property (nonatomic, strong) NSString *deviceID;

- (NSDictionary *)apiUpdateJSON;
@end
