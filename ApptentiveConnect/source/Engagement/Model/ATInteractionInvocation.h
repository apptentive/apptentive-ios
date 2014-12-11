//
//  ATInteractionInvocation.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATInteractionInvocation : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy) NSString *interactionID;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, retain) NSDictionary *criteria;

+ (ATInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary;

@end
