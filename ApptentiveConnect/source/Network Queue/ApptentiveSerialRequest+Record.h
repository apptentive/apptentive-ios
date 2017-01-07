//
//  ApptentiveSerialRequest+Record.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/6/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequest.h"

@interface ApptentiveSerialRequest (Record)

+ (void)enqueueRequestWithPath:(NSString *)path noncePrefix:(NSString *)noncePrefix payload:(NSDictionary *)payload inContext:(NSManagedObjectContext *)context;

+ (void)enqueueSurveyResponseWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;

+ (void)enqueueEventWithLabel:(NSString *)label interactionIdentifier:(NSString *)interactionIdenfier userInfo:userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData inContext:(NSManagedObjectContext *)context;

@end
