//
//  ATInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATInteraction : NSObject <NSCoding> {
	
}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, assign) int priority;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSDictionary *configuration;
@property (nonatomic, retain) NSDictionary *criteria;

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary;

@end
