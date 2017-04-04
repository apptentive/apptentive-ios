//
//  ApptentiveSerialRequest+Record.h
//  Apptentive
//
//  Created by Frank Schmitt on 1/6/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequest.h"

@class ApptentiveMessage;


/**
 This category on `ApptentiveSerialRequest` adds convenience methods for
 queueing events, survey responses, and messages.
 */
@interface ApptentiveSerialRequest (Record)

/**
 Creates and enqueues a request with the specified parameters.

 @param path The path to use to build the URL.
 @param containerName The key to use in the top-level JSON object, whose value
 is the payload dictionary.
 @param noncePrefix The prefix to use in the request's nonce.
 @param payload The payload to be JSON encoded.
 @param context The managed object context to use to create the request.
 */
+ (void)enqueueRequestWithPath:(NSString *)path containerName:(NSString *)containerName noncePrefix:(NSString *)noncePrefix payload:(NSDictionary *)payload conversation:(ApptentiveConversation *)conversation inContext:(NSManagedObjectContext *)context;

/**
 Creates and enqueues a request for transmitting survey answers.

 @param answers The dictionary representing the answers.
 @param identifier The survey identifier, used in creating the path.
 @param context The managed object context to use to create the request.
 */
+ (void)enqueueSurveyResponseWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier conversation:(ApptentiveConversation *)conversation inContext:(NSManagedObjectContext *)context;

/**
 Creates and enqueues a request for transmitting an event.

 @param label The event label.
 @param interactionIdenfier The interaction identifier, if the event is
 associated with an interaction.
 @param customData Any custom data that should be included with the event.
 @param extendedData Any extended data that should be included with the event.
 @param context The managed object context to use to create the request.
 */
+ (void)enqueueEventWithLabel:(NSString *)label interactionIdentifier:(NSString *)interactionIdenfier userInfo:userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData conversation:(ApptentiveConversation *)conversation inContext:(NSManagedObjectContext *)context;

/**
 Creates and enqueues a message transmission.

 @param message The message to be sent.
 @param context The managed object context to use to create the request.
 */
+ (void)enqueueMessage:(ApptentiveMessage *)message conversation:(ApptentiveConversation *)conversation inContext:(NSManagedObjectContext *)context;

@end
